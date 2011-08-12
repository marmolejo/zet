;;--------------------------------------------------------------------------
POSTCODE MACRO parm1
						mov		al, parm1
						out		IO_POST, al
ENDM
;;--------------------------------------------------------------------------
SET_INT_VECTOR MACRO parm1, parm2, parm3
                        mov     ax, parm3
                        mov     ds:[parm1*4], ax
                        mov     ax, parm2
                        mov     ds:[parm1*4+2], ax
ENDM
;;--------------------------------------------------------------------------
PUSHALL MACRO
                        push    ax
                        push    cx
                        push    dx
                        push    bx
                        push    bp
                        push    si
                        push    di
ENDM
;;--------------------------------------------------------------------------
POPALL MACRO
                        pop     di
                        pop     si
                        pop     bp
                        pop     bx
                        pop     dx
                        pop     cx
                        pop     ax
ENDM
;;--------------------------------------------------------------------------
CALL_SP	MACRO param1
						mov	sp,$+5		;point to return address
						jmp	(param1)	;jump to subroutine
ENDM
