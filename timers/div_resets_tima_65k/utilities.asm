
	INCLUDE "hardware.inc"
	INCLUDE "header.inc"
	
;--------------------------------------------------------------------------
;-                          GENERAL FUNCTIONS                             -
;--------------------------------------------------------------------------	

	SECTION	"Utilities",HOME
	
;--------------------------------------------------------------------------
;- memset()    d = value    hl = start address    bc = size               -
;--------------------------------------------------------------------------

memset::
	
	ld	a,d
	ld	[hl+],a
	dec	bc
	ld	a,b
	or	a,c
	jr	nz,memset
	
	ret
	
;--------------------------------------------------------------------------
;- memset_rand()    hl = start address    bc = size                       -
;--------------------------------------------------------------------------

memset_rand::
	

	ret
	
;--------------------------------------------------------------------------
;- memcopy()    bc = size    hl = source address    de = dest address     -
;--------------------------------------------------------------------------

memcopy::
	
	ld	a,[hl+]
	ld	[de],a
	inc	de
	dec	bc
	ld	a,b
	or	a,c
	jr	nz,memcopy
	
	ret

;--------------------------------------------------------------------------
;- memcopy_inc()    b = size    c = increase    hl = source    de = dest  -
;--------------------------------------------------------------------------

memcopy_inc::
	
	ld	a,[hl]
	ld	[de],a
	
	inc	de ; increase dest
	
	ld	a,b ; save b
	ld	b,$00
	add	hl,bc ; increase source
	ld	b,a ; restore b
	
	dec	b
	jr	nz,memcopy_inc
	
	ret

;--------------------------------------------------------------------------
;-                            JOYPAD HANDLER                              -
;--------------------------------------------------------------------------	

;--------------------------------------------------------------------------
;-                               Variables                                -
;--------------------------------------------------------------------------	

	SECTION	"JoypadHandlerVariables",HRAM

_joy_old:		DS	1			
joy_held::		DS	1
joy_pressed::	DS	1

;--------------------------------------------------------------------------
;-                               Functions                                -
;--------------------------------------------------------------------------	

	SECTION	"JoypadHandler",HOME
	
;--------------------------------------------------------------------------
;- scan_keys()                                                            -
;--------------------------------------------------------------------------

scan_keys::
	
	ld	a,[joy_held]
	ld	[_joy_old],a   ; current state = old state
	ld	c,a            ; c = old state
	
	ld	a,$10
	ld	[rP1],a  ; select P14
	ld	a,[rP1]
	ld	a,[rP1]  ; wait a few cycles
	cpl	               ; complement A
	and	a,$0F          ; get only first 4 bits
	swap	a          ; swap it
	ld	b,a            ; store A in B
	ld	a,$20
	ld	[rP1],a        ; select P15
	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]  ; Wait a few MORE cycles
	cpl
	and	a,$0F
	or	a,b            ; put A and B together
	
	ld	[joy_held],a
	
	xor	a,c            ; c = old state
	and	a,c
	
	ld	[joy_pressed],a
	
	ld	a,$00          ; deselect P14 and P15
	ld	[rP1],a  ; RESET Joypad

	ret


;--------------------------------------------------------------------------
;-                              ROM HANDLER                               -
;--------------------------------------------------------------------------	


;--------------------------------------------------------------------------
;-                               Variables                                -
;--------------------------------------------------------------------------	

	SECTION	"RomHandlerVariables",BSS

rom_stack:		DS	$20
rom_position:	DS	1

;--------------------------------------------------------------------------
;-                               Functions                                -
;--------------------------------------------------------------------------	

	SECTION	"RomHandler",HOME

;--------------------------------------------------------------------------
;- rom_handler_init()                                                     -
;--------------------------------------------------------------------------
	
rom_handler_init::
	
	xor	a,a
	ld	[rom_position],a	
	
	ld	b,1
	call	rom_bank_set  ; select rom bank 1
	
	ret	
	
;--------------------------------------------------------------------------
;- rom_bank_pop()                                                         -
;--------------------------------------------------------------------------
	
rom_bank_pop::
	ld	hl,rom_position
	dec	[hl]
	
	ld	hl,rom_stack
	
	ld	d,$00
	ld	a,[rom_position]
	ld	e,a
	
	add	hl,de             ; hl now holds the pointer to the bank we want to change to
	ld	a,[hl]            ; and a the bank we want to change to
	
	ld	[$2000],a         ; select rom bank
	
	ret

;--------------------------------------------------------------------------
;- rom_bank_push()                                                        -
;--------------------------------------------------------------------------
	
rom_bank_push::
	ld	hl,rom_position
	inc	[hl]

	ret
	
;--------------------------------------------------------------------------
;- rom_bank_set()    b = bank to change to                                -
;--------------------------------------------------------------------------
	
rom_bank_set::
	ld	hl,rom_stack
	
	ld	d,$00
	ld	a,[rom_position]
	ld	e,a
	add	hl,de
	
	ld	a,b               ; hl = pointer to stack, a = bank to change to
	
	ld	[hl],a
	ld	[$2000],a         ; select rom bank
	
	ret
	
;--------------------------------------------------------------------------
;- rom_bank_push_set()    b = bank to change to                           -
;--------------------------------------------------------------------------
	
rom_bank_push_set::
	ld	hl,rom_position
	inc	[hl]
	
	ld	hl,rom_stack
	
	ld	d,$00
	ld	a,[rom_position]
	ld	e,a
	add	hl,de
	
	ld	a,b               ; hl = pointer to stack, a = bank to change to
	
	ld	[hl],a
	ld	[$2000],a         ; select rom bank

	ret

;--------------------------------------------------------------------------
;- ___long_call()    hl = function    b = bank where it is located        -
;--------------------------------------------------------------------------

___long_call::
	push	hl
	call	rom_bank_push_set
	pop	hl
	call	._jump_to_function
	call	rom_bank_pop
	ret
._jump_to_function:
	jp	[hl]


	

