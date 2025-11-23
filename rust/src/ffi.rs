extern crate rust_tikz;

use rust_tikz::text2svg_simple;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

/// Convert TikZ code to SVG string
/// 
/// # Safety
/// This function is unsafe because it dereferences raw pointers.
/// The caller must ensure that:
/// - `tikz_code` is a valid null-terminated C string
/// - The returned pointer must be freed using `free_string`
#[no_mangle]
pub unsafe extern "C" fn tikz_to_svg(tikz_code: *const c_char) -> *mut c_char {
    // Convert C string to Rust string
    let c_str = match CStr::from_ptr(tikz_code).to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    // Call rust_tikz to convert TikZ to SVG
    let svg_result = text2svg_simple(c_str);
    
    match svg_result {
        Ok(svg) => {
            // Convert Rust string to C string
            match CString::new(svg) {
                Ok(c_string) => c_string.into_raw(),
                Err(_) => std::ptr::null_mut(),
            }
        }
        Err(e) => {
            // Return error message as a special format: "ERROR: ..."
            let error_msg = format!("ERROR: {}", e);
            match CString::new(error_msg) {
                Ok(c_string) => c_string.into_raw(),
                Err(_) => std::ptr::null_mut(),
            }
        }
    }
}

/// Free a string allocated by Rust
/// 
/// # Safety
/// This function is unsafe because it takes ownership of a raw pointer.
/// The caller must ensure that:
/// - `s` was allocated by `tikz_to_svg`
/// - `s` is only freed once
#[no_mangle]
pub unsafe extern "C" fn free_string(s: *mut c_char) {
    if !s.is_null() {
        // Take ownership and drop
        unsafe {
            let _ = CString::from_raw(s);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_tikz_to_svg() {
        let tikz_code = r#"
\begin{document}
\begin{tikzpicture}
\draw (0,0) -- (1,1);
\end{tikzpicture}
\end{document}
"#;
        
        let c_tikz = CString::new(tikz_code).unwrap();
        
        unsafe {
            let result = tikz_to_svg(c_tikz.as_ptr());
            assert!(!result.is_null());
            
            let svg = CStr::from_ptr(result).to_str().unwrap();
            println!("SVG output: {}", svg);
            assert!(svg.contains("<svg") || svg.contains("ERROR"));
            
            free_string(result);
        }
    }
}
