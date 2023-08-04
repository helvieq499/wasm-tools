(module
  (import "wasi_snapshot_preview1" "args_sizes_get" (func $args_size (param i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "args_get" (func $args_get (param i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_read" (func $read (param i32 i32 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_write" (func $write (param i32 i32 i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "fd_filestat_get" (func $filestat (param i32 i32) (result i32)))
  (import "wasi_snapshot_preview1" "path_open" (func $open (param i32 i32 i32 i32 i32 i64 i64 i32 i32) (result i32)))
  
  (memory 1)
  (export "memory" (memory 0))
  
  (data (i32.const 1) "\nUsage: wasm-attach (Target .wasm file) (File to attach)\n") ;; 57
  (data (i32.const 73) "0x??: ") ;; 6
  (data (i32.const 84)  "\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\fa\00") ;; jump table for error messages
  (data (i32.const 100) "\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00")
  (data (i32.const 116) "\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00")
  (data (i32.const 132) "\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00")
  (data (i32.const 148) "\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00")
  (data (i32.const 164) "\ec\00\ec\00\ec\00\11\01\ec\00\ec\00\ec\00\ec\00")
  (data (i32.const 180) "\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00")
  (data (i32.const 196) "\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00")
  (data (i32.const 212) "\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00\ec\00")
  (data (i32.const 228) "\ec\00\ec\00\ec\00\ec\00")
  (data (i32.const 236) "Unknown error\00") ;; 14
  (data (i32.const 250) "Bad fd (use `--dir .`)\00") ;; 23
  (data (i32.const 273) "No such file.\00") ;; 14
  
  (func
    (export "_start")
    (local $argc i32)
    (local $argvc i32)
    (local $argv i32)
    (local $sp i32)
    (local $len i32)
    (local $len_len i32)
    (local $dest_fd i32)
    (local $dest i32)
    (local $dest_size i32)
    (local $src_fd i32)
    (local $src i32)
    (local $src_size i32)
    (local $src_len i32)
    (local $src_len_leb i32)
    (local $src_len_leb_len i32)
    
    (local.set $sp (i32.const 512))
    
    ;; get argc and arcvc
    (drop (call $args_size (local.get $sp) (i32.add (local.get $sp) (i32.const 4))))
    (local.set $argc (i32.load (local.get $sp)))
    (local.set $argvc (i32.load (i32.add (local.get $sp) (i32.const 4))))
    
    ;; assert argc == 3
    (if
      (i32.ne (i32.const 3) (local.get $argc))
      (then
        (i32.store (local.get $sp) (i32.const 1)) ;; offset
        (i32.store (i32.add (local.get $sp) (i32.const 4)) (i32.const 72)) ;; length
        
        (drop (call $write
          (i32.const 2) ;; stderr 
          (local.get $sp) ;; ptr to descriptor list
          (i32.const 1) ;; amount of descriptors
          (i32.const 65531) ;; amount written
        ))
        
        return
      )
    )
        
    ;; read args
    (drop (call $args_get
      (local.get $sp)
      (i32.add 
        (local.get $sp)
        (i32.mul
          (i32.const 4)
          (local.get $argc)
        )
      )
    ))
    
    (local.set $argv (local.get $sp))
    
    (local.set $sp 
      (i32.add
        (local.get $sp)
        (i32.add
          (local.get $argvc)
          (i32.mul (local.get $argc) (i32.const 4))
        )
      )
    )

    (local.set $dest (local.get $sp))
    (call $load_file
      (i32.load (i32.add (local.get $argv) (i32.const 4)))
      (local.get $sp)
      (i64.const 262210)
    )
    
    local.tee $dest_size
    local.get $sp
    i32.add
    local.set $sp
    local.set $dest_fd
    
    (local.set $src (local.get $sp))
    (call $load_file
      (i32.load (i32.add (local.get $argv) (i32.const 8)))
      (local.get $sp)
      (i64.const 262210)
    )
    
    local.tee $src_size
    local.get $sp
    i32.add
    local.set $sp
    local.set $src_fd
    
    (local.tee $src_len
      (call $strlen
        (i32.load
          (i32.add (local.get $argv) (i32.const 8))
        )
      )
    )
    
    (call $leb128u_encode (local.get $sp))
    (local.tee $src_len_leb (local.get $sp))
    (local.tee $src_len_leb_len (call $strlen))
    (local.set $sp (i32.add (local.get $sp)))

    (call $leb128u_encode (i32.add (local.get $src_size) (i32.add (local.get $src_len) (i32.const 1))) (local.get $sp))
    (local.tee $len (local.get $sp))
    (local.tee $len_len (call $strlen))
    (local.set $sp (i32.add (local.get $sp)))
        
    (i32.store (local.get $sp) (local.get $dest))
    (i32.store (i32.add (local.get $sp) (i32.const 4)) (local.get $dest_size))
    (i32.store (i32.add (local.get $sp) (i32.const 8)) (i32.const 0))
    (i32.store (i32.add (local.get $sp) (i32.const 12)) (i32.const 1))
    (i32.store (i32.add (local.get $sp) (i32.const 16)) (local.get $len))
    (i32.store (i32.add (local.get $sp) (i32.const 20)) (local.get $len_len))
    (i32.store (i32.add (local.get $sp) (i32.const 24)) (local.get $src_len_leb))
    (i32.store (i32.add (local.get $sp) (i32.const 28)) (local.get $src_len_leb_len))
    (i32.store (i32.add (local.get $sp) (i32.const 32)) (i32.load (i32.add (local.get $argv) (i32.const 8))))
    (i32.store (i32.add (local.get $sp) (i32.const 36)) (local.get $src_len))
    (i32.store (i32.add (local.get $sp) (i32.const 40)) (local.get $src))
    (i32.store (i32.add (local.get $sp) (i32.const 44)) (local.get $src_size))
    
    (drop (call $write
      (i32.const 1)
      (local.get $sp)
      (i32.const 6)
      (i32.const 65531)
    ))
  )
  
  (func $leb128u_encode
    (param $num i32)
    (param $ptr i32)
    (local $val i32)
    
    (loop
      (local.set $val (i32.and (local.get $num) (i32.const 127)))
      (local.set $num (i32.shr_u (local.get $num) (i32.const 7)))
      
      (if
        (local.get $num)
        (then
          (i32.store (local.get $ptr) (i32.or (local.get $val) (i32.const 128)))
          (local.set $ptr (i32.add (local.get $ptr) (i32.const 1)))
          br 1
        )
        (else
          (i32.store (local.get $ptr) (local.get $val))
          br 0
        )
      )
    )
  )
  
  (func $print_error
    (param $sp i32)
    (param $err i32)
    (local $str i32)
    
    (call $to_hex (local.get $err) (i32.const 75))
    (i32.store (local.get $sp) (i32.const 57))
    (i32.store (i32.add (local.get $sp) (i32.const 4)) (i32.const 7))
    
    (local.set $str (i32.load16_u (i32.add (i32.const 82) (i32.add (local.get $err) (local.get $err)))))
    (i32.store (i32.add (local.get $sp) (i32.const 8)) (local.get $str))
    (i32.store (i32.add (local.get $sp) (i32.const 12)) (call $strlen (local.get $str)))
    
    (i32.store (i32.add (local.get $sp) (i32.const 16)) (i32.const 1))
    (i32.store (i32.add (local.get $sp) (i32.const 20)) (i32.const 1))
    
    (drop (call $write
      (i32.const 2) ;; stderr
      (local.get $sp)
      (i32.const 3)
      (i32.const 65531)
    ))
    
    unreachable ;; crash
  )
  
  (func $to_hex
    (param $num i32)
    (param $out i32)
    
    (i32.store8 (local.get $out) (call $single_to_hex (i32.div_u (local.get $num) (i32.const 16))))
    (i32.store8 (i32.add (local.get $out) (i32.const 1)) (call $single_to_hex (i32.rem_u (local.get $num) (i32.const 16))))
  )
  
  (func $single_to_hex
    (param $num i32)
    (result i32)
    
    (i32.add 
      (if (result i32)
        (i32.lt_u (local.get $num) (i32.const 10))
        (then (i32.const 48))
        (else (i32.const 87))
      ) 
      (local.get $num)
    )
  )
  
  (func $load_file
    (param $str i32)
    (param $sp i32)
    (param $rights i64)
    (result i32 i32)
    (local $fd i32)
    (local $size i32)
    (local $err i32)
    
    (local.tee $err (call $open
      (i32.const 4)
      (i32.const 1)
      (call $as_str (local.get $str))
      (i32.const 0)
      (local.get $rights)
      (i64.const 0)
      (i32.const 0)
      (local.get $sp)
    ))
    
    (if (then
      (call $print_error (local.get $sp) (local.get $err))
    ))

    (local.tee $fd (i32.load (local.get $sp)))
    (local.tee $size (i32.wrap_i64 (call $file_size (local.get $fd) (local.get $sp))))
    
    (i32.store (local.get $sp) (local.get $sp))
    (i32.store (i32.add (local.get $sp) (i32.const 4)) (local.get $size))
    (call $read 
      (local.get $fd)
      (local.get $sp)
      (i32.const 1)
      (i32.const 65531)
    )
    
    local.tee $err
    (if (then
      (call $print_error (local.get $sp) (local.get $err))
    ))
  )
  
  (func $file_size
    (param $fd i32)
    (param $sp i32)
    (result i64)
    
    (drop (call $filestat
      (local.get $fd)
      (local.get $sp)
    ))
    
    (i64.load (i32.add (local.get $sp) (i32.const 32)))
  )
  
  (func $as_str
    (param $ptr i32)
    (result i32 i32)
    
    local.get $ptr
    (call $strlen (local.get $ptr))
  )
  
  (func $strlen
    (param $ptr i32)
    (result i32)
    (local $index i32)
    
    (local.set $index (local.get $ptr))
    
    (loop
      (if
        (i32.eq 
          (i32.load8_u (local.get $index)) 
          (i32.const 0)
        )
        (then (br 0))
        (else 
          (local.set $index (i32.add (local.get $index) (i32.const 1)))
          br 1
        )
      )
    )
    
    (i32.sub (local.get $index) (local.get $ptr))
  )
)