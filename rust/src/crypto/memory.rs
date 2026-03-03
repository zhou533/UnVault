// Items in this module are used by other crypto modules (encryption, mnemonic, etc.)
// which are built in later steps. Allow dead_code during incremental development.
#![allow(dead_code)]

use zeroize::Zeroize;

use crate::error::{Result, UnvaultError};

/// Attempts to lock a memory region to prevent swapping to disk.
///
/// This is a best-effort operation. On iOS sandboxed environments,
/// `mlock` may fail — in that case we log a warning but return `Ok(())`.
///
/// # Safety
/// The caller must ensure `ptr` and `len` describe a valid memory region.
pub(crate) fn mlock_region(ptr: *const u8, len: usize) -> Result<bool> {
    if len == 0 {
        return Ok(false);
    }

    let ret = unsafe { libc::mlock(ptr as *const libc::c_void, len) };

    if ret == 0 {
        Ok(true)
    } else {
        // Graceful degradation: mlock failure is not fatal.
        // iOS sandbox and some CI environments deny mlock.
        let errno = std::io::Error::last_os_error();
        eprintln!("warning: mlock failed (non-fatal, zeroize still active): {}", errno);
        Ok(false)
    }
}

/// Unlocks a previously locked memory region.
///
/// # Safety
/// The caller must ensure `ptr` and `len` describe a valid, previously locked region.
pub(crate) fn munlock_region(ptr: *const u8, len: usize) -> Result<()> {
    if len == 0 {
        return Ok(());
    }

    let ret = unsafe { libc::munlock(ptr as *const libc::c_void, len) };

    if ret != 0 {
        let errno = std::io::Error::last_os_error();
        return Err(UnvaultError::MemoryLock(format!("munlock failed: {}", errno)));
    }

    Ok(())
}

/// A byte buffer that attempts `mlock` on allocation and performs
/// `zeroize` + `munlock` on drop.
///
/// If `mlock` fails (e.g. iOS sandbox), the buffer degrades gracefully:
/// zeroize still runs on drop, but memory may be swappable.
///
/// No `Debug` or `Display` implementation to prevent accidental logging.
pub(crate) struct LockedBuffer {
    data: Vec<u8>,
    locked: bool,
}

// Intentionally no Debug impl — prevents accidental logging of buffer contents.

impl LockedBuffer {
    /// Creates a new zero-initialized buffer of `size` bytes,
    /// attempting to lock it in memory.
    pub fn new(size: usize) -> Self {
        let data = vec![0u8; size];
        let locked = if !data.is_empty() {
            mlock_region(data.as_ptr(), data.len()).unwrap_or(false)
        } else {
            false
        };

        Self { data, locked }
    }

    /// Creates a `LockedBuffer` from an existing `Vec<u8>`,
    /// attempting to lock it in memory.
    pub fn from_vec(data: Vec<u8>) -> Self {
        let locked = if !data.is_empty() {
            mlock_region(data.as_ptr(), data.len()).unwrap_or(false)
        } else {
            false
        };

        Self { data, locked }
    }

    /// Returns an immutable reference to the buffer contents.
    pub fn as_slice(&self) -> &[u8] {
        &self.data
    }

    /// Returns a mutable reference to the buffer contents.
    pub fn as_mut_slice(&mut self) -> &mut [u8] {
        &mut self.data
    }

    /// Returns the length of the buffer.
    pub fn len(&self) -> usize {
        self.data.len()
    }

    /// Returns true if the buffer is empty.
    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }

    /// Returns whether the buffer was successfully locked in memory.
    pub fn is_locked(&self) -> bool {
        self.locked
    }
}

impl Drop for LockedBuffer {
    fn drop(&mut self) {
        // Always zeroize, regardless of lock status.
        self.data.zeroize();

        // Unlock if we successfully locked.
        if self.locked {
            let _ = munlock_region(self.data.as_ptr(), self.data.capacity());
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn locked_buffer_new_creates_zeroed_buffer() {
        let buf = LockedBuffer::new(32);
        assert_eq!(buf.len(), 32);
        assert!(!buf.is_empty());
        assert_eq!(buf.as_slice(), &[0u8; 32]);
    }

    #[test]
    fn locked_buffer_new_empty() {
        let buf = LockedBuffer::new(0);
        assert_eq!(buf.len(), 0);
        assert!(buf.is_empty());
        assert!(!buf.is_locked());
    }

    #[test]
    fn locked_buffer_from_vec() {
        let data = vec![1u8, 2, 3, 4, 5];
        let buf = LockedBuffer::from_vec(data);
        assert_eq!(buf.len(), 5);
        assert_eq!(buf.as_slice(), &[1, 2, 3, 4, 5]);
    }

    #[test]
    fn locked_buffer_mut_access() {
        let mut buf = LockedBuffer::new(4);
        buf.as_mut_slice().copy_from_slice(&[10, 20, 30, 40]);
        assert_eq!(buf.as_slice(), &[10, 20, 30, 40]);
    }

    #[test]
    fn locked_buffer_drop_does_not_panic() {
        let buf = LockedBuffer::new(64);
        drop(buf);
        // If we get here, drop didn't panic.
    }

    #[test]
    fn locked_buffer_zeroizes_on_drop() {
        let buf = LockedBuffer::from_vec(vec![0xAA; 128]);
        let ptr = buf.as_slice().as_ptr();
        let len = buf.len();

        drop(buf);

        // After drop, the memory should be zeroed.
        // This is best-effort verification — the allocator may reuse the memory.
        // Using unsafe to read freed memory is UB in general, but in test context
        // with a simple allocator, the zeroized bytes are likely still in place.
        unsafe {
            let slice = std::slice::from_raw_parts(ptr, len);
            // At least some of the bytes should be zero (zeroize ran).
            let zero_count = slice.iter().filter(|&&b| b == 0).count();
            assert!(
                zero_count > len / 2,
                "expected most bytes to be zeroed after drop, but only {}/{} were zero",
                zero_count,
                len
            );
        }
    }

    #[test]
    fn mlock_region_empty_returns_false() {
        let result = mlock_region(std::ptr::null(), 0);
        assert!(result.is_ok());
        assert!(!result.unwrap());
    }

    #[test]
    fn munlock_region_empty_succeeds() {
        let result = munlock_region(std::ptr::null(), 0);
        assert!(result.is_ok());
    }

    #[test]
    fn mlock_region_valid_buffer_does_not_panic() {
        let data = vec![0u8; 4096];
        let result = mlock_region(data.as_ptr(), data.len());
        // Should succeed (Ok(true)) or gracefully degrade (Ok(false)).
        assert!(result.is_ok());

        if result.unwrap() {
            let unlock = munlock_region(data.as_ptr(), data.len());
            assert!(unlock.is_ok());
        }
    }
}
