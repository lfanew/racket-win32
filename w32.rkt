#lang racket

(require ffi/unsafe
         ffi/unsafe/define)

(define _HWND (_cpointer/null 'HWND))
(define _WORD _ushort)
(define _DWORD _int32)
(define _ULONG_PTR _uint64)

(define-ffi-definer define-user32 (ffi-lib "User32.dll"))

(define-user32 MessageBoxA (_fun _HWND _string _string _uint -> _int))

(define _MB_ABORTRETRYIGNORE #x2)
(define _MB_CANCELTRYCONTINUE #x6)
(define _MB_HELP #x4000)
(define _MB_OK #x0)
(define _MB_OKCANCEL #x1)
(define _MB_RETRYCANCEL #x5)
(define _MB_YESNO #x4)
(define _MB_YESNOCANCEL #x3)

(define (message-box title text)
  (MessageBoxA #f text title _MB_OK)
  (void))

(define (message-box/yes-no title text)
  (equal? (MessageBoxA #f text title _MB_YESNO) 6))

;;;;;;;;;;;;;;;;;

(define-cstruct _POINT ([x _long]
                        [y _long]))

(define-user32 GetCursorPos (_fun (m : (_ptr o _POINT))
                                  -> (r : _bool)
                                  -> (and r m)))

(define-user32 SetCursorPos (_fun (x : _int) (y : _int) -> _bool))

;;;;;;;;;;;;;;;;;;

(define _SM_CXSCREEN 0)
(define _SM_CYSCREEN 1)

(define-user32 GetSystemMetrics (_fun _int -> _int))

(define (screen-width)
  (GetSystemMetrics _SM_CXSCREEN))

(define (screen-height)
  (GetSystemMetrics _SM_CYSCREEN))

(define (mouse-coord-to-abs coord width-or-height)
  (+ (quotient (* 65536 coord) width-or-height)
     (if (< coord 0) -1 1)))

(define _INPUT_MOUSE 0)
(define _INPUT_KEYBOARD 1)
(define _INPUT_HARDWARE 2)

(define-cstruct _MOUSEINPUT ([dx _long]
                             [dy _long]
                             [mouseData _DWORD]
                             [dwFlags _DWORD]
                             [time _DWORD]
                             [dwExtraInfo _ULONG_PTR]))

(define-cstruct _KEYBDINPUT ([wVk _WORD]
                             [wScan _WORD]
                             [dwFlags _DWORD]
                             [time _DWORD]
                             [dwExtraInfo _ULONG_PTR]))

(define-cstruct _HARDWAREINPUT ([uMsg _DWORD]
                                [wParamL _WORD]
                                [wParamH _WORD]))

(define _INPUT_UNION (make-union-type _MOUSEINPUT _KEYBDINPUT _HARDWAREINPUT))

(define-cstruct _INPUT ([type _DWORD]
                        [DUMMYUNIONNAME _INPUT_UNION]))

(define-user32 SendInput (_fun _uint _INPUT-pointer _int -> _uint))

(define my-input-union
  (cast (make-MOUSEINPUT 0 500 0 #x1 0 0)
        _MOUSEINPUT
        _INPUT_UNION))

(define my-input (make-INPUT 0 my-input-union))

(define (make-mouse-event x y data flags)
  (let* ([m (make-MOUSEINPUT x y data flags 0 0)]
         [mu (cast m _MOUSEINPUT _INPUT_UNION)])
    (make-INPUT 0 mu)))

(define (send-input-event evt)
  (SendInput 1 evt (ctype-sizeof _INPUT)))

(define (mouse-move x y [relative #f])
  (let ([flags (if relative #x1 (bitwise-ior #x1 #x8000))]
        [dx (if relative x (mouse-coord-to-abs x (screen-width)))]
        [dy (if relative y (mouse-coord-to-abs y (screen-height)))])
    (> (send-input-event (make-mouse-event dx dy 0 flags)) 0)))

; (for ([i (in-range 100)])
;   (let ([m (GetCursorPos)])
;     (when m
;       (printf "~a,~a\r\n" (POINT-x m) (POINT-y m))
;       (sleep 0.1))))

(provide message-box
         message-box/yes-no
         screen-width
         screen-height
         mouse-move)