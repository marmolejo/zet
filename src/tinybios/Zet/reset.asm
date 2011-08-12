;;---------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; MAIN BIOS Entry Point:  
;; on Reset - Processor starts at this location. This is the first instruction
;; that gets executed on start up. So we just immediately jump to the entry
;; Point for the Bios which is the POST (which stands for Power On Self Test).
                        org     0fff0h					;; Power-up Entry Point
                        jmp     far ptr reset
						;db	0eah						; HARD CODE FAR JUMP TO SET
						;dw	offset reset				;  OFFSET
						;dw	0f000h	    				;; Boot up bios

                        org     0fff5h					;; ASCII Date ROM was built - 8 characters in MM/DD/YY
BIOS_BUILD_DATE         equ     "09/09/10\n"
MSG2:                   db      BIOS_BUILD_DATE

                        org     0fffeh					;; Put the SYS_MODEL_ID
                        db      SYS_MODEL_ID            ;; here
                        db      0
