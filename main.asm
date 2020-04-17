  .inesprg 1	; 1x 16KB PRG code
  .ineschr 1	; 1x  8KB CHR data
  .inesmap 0	; mapper 0 = NROM, no bank swapping
  .inesmir 1	; background mirroring
  

;;;;;;;;;;;;;;;

  .rsset $0000
	
seed		.rs 1	; Seed for the Pseudo Random Number Generator
rand		.rs 1	; Address to store random number
nextPPUAddr	.rs 1	; Address to store the next PPU address available to copy
ballXAddr	.rs 1	; Address to store projectile's X coord when spawned
cooldown	.rs 1	; Address to store projectile's cooldown after shooting

difficulty1	.rs 1	; Difficulty level
difficulty2	.rs 1





  .bank 0
  .org $C000

vblankwait:			; First wait for vblank to make sure PPU is ready
	BIT $2002
	BPL vblankwait
	RTS

RESET:
	SEI				; disable IRQs
	CLD				; disable decimal mode
  
	JSR vblankwait

clrmem:
	LDA #$FE
	STA $0200, x
	INX
	BNE clrmem
	JSR vblankwait
   


LoadPalettes:
	LDA $2002				; read PPU status to reset the high/low latch
	LDA #$3F
	STA $2006				; write the high byte of $3F00 address
	LDA #$00
	STA $2006				; write the low byte of $3F00 address
	LDX #$00				; start out at 0
LoadPalettesLoop:
	LDA palette, x			; load data from address (palette + the value in x)
	STA $2007				; write to PPU
	INX						; X = X + 1
	CPX #$20             	; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
	BNE LoadPalettesLoop  	; Branch to LoadPalettesLoop if compare was Not Equal to zero
							; if compare was equal to 32, keep going down
							
							
ClearPPU:
	LDA #$FF				; We use FF sprite, which is blank on the chr file
	LDX #$00
ClearPPULoop:
	STA $0200, X			; Set ppu address to zero ($0200 + x)
	INX
	CPX #$FF
	BNE ClearPPULoop		; If X != FF repeat, will clear $0200-$02FF

LoadSprites:
	LDX #$00				; start at 0
LoadSpritesLoop:
	LDA sprites, x			; load data from address (sprites + x)
	STA $0200, x			; store into RAM address ($0200 + x)
	INX						; X = X + 1
	CPX #$10				; Compare X to hex $10, decimal 16
	BNE LoadSpritesLoop		; Branch to LoadSpritesLoop if compare was Not Equal to zero
							; if compare was equal to 16, continue down


	LDA #%10010000	; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	STA $2000

	LDA #%00011110	; enable sprites, enable background, no clipping on left side
	STA $2001
	
	LDA #$3E
	STA seed
	
	LDA #$10		; $0210 will be the start for the projectiles, will extend until $0220
	STA nextPPUAddr
	
	LDA #$00
	STA cooldown

main:
	JMP main		;jump back to main, infinite loop, waiting for NMI



NMI:				; Aki komiensa la peska
	LDA #$00
	STA $2003       ; set the low byte (00) of the RAM address
	LDA #$02
	STA $4014       ; set the high byte (02) of the RAM address, start the transfer



	; This is the PPU clean up section, so rendering the next frame starts properly.
	LDA #%10010000	; Enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	STA $2000
	LDA #%00011110	; Enable sprites, enable background, no clipping on left side
	STA $2001
	LDA #$00		; Tell the ppu there is no background scrolling
	STA $2005
	STA $2005
    
	; All graphics updates done by here, run game engine

IncreaseCooldown:
	INC cooldown	; Increase cooldown every frame


ProjectileTravel:	; Decrease the 4 projectiles' Y coord (Y = 0 equals top of the screen)
	DEC $0210
	DEC $0210
	DEC $0210
	DEC $0214
	DEC $0214
	DEC $0214
	DEC $0218
	DEC $0218
	DEC $0218
	DEC $021C
	DEC $021C
	DEC $021C
CheckTravelEnd:		; If the projectiles reach the top of the screen they despawn
	LDX $0210
	CPX #$10
	BEQ despawnProjectile1
check2:
	LDX $0214
	CPX #$10
	BEQ despawnProjectile2
check3:
	LDX $0218
	CPX #$10
	BEQ despawnProjectile3
check4:
	LDX $021C
	CPX #$10
	BEQ despawnProjectile4
	JMP LatchController		; Jump to read controller input
	
despawnProjectile1:
	LDA #$FF				; We will use sprite FF (which is blank on the chr file)
	STA $0210
	STA $0211
	STA $0212
	STA $0213
	JMP check2		; Jump back to check projectile 2
despawnProjectile2:
	LDA #$FF
	STA $0214
	STA $0215
	STA $0216
	STA $0217
	JMP check3
despawnProjectile3:
	LDA #$FF
	STA $0218
	STA $0219
	STA $021A
	STA $021B
	JMP check4
despawnProjectile4:
	LDA #$FF
	STA $021C
	STA $021D
	STA $021E
	STA $021F
	; No Jump instruction required, continue to read input

LatchController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016			; tell both the controllers to latch buttons


ReadA: 
  LDA $4016			; player 1 - A
  AND #%00000001	; only look at bit 0
  BEQ ReadADone		; branch to ReadADone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)

	LDX cooldown
	CPX #$20				
	BPL spawnProjectile	; If cooldown >= hex 20, shoot projectile
	

ReadADone:			; handling this button is done
  

ReadB: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadBDone		; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)

ReadBDone:			; handling this button is done

ReadSelect: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadSelectDone; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)

ReadSelectDone:		; handling this button is done

ReadStart: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadStartDone	; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)

ReadStartDone:		; handling this button is done

ReadUp: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadUpDone	; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)

ReadUpDone:			; handling this button is done

ReadDown: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadDownDone	; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)

ReadDownDone:		; handling this button is done

ReadLeft: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadLeftDone	; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)
  DEC $0203
  DEC $0207
  DEC $020B
  DEC $020F
  DEC $0203
  DEC $0207
  DEC $020B
  DEC $020F
ReadLeftDone:		; handling this button is done

ReadRight: 
  LDA $4016			; player 1 - B
  AND #%00000001	; only look at bit 0
  BEQ ReadRightDone	; branch to ReadBDone if button is NOT pressed (0)
					; add instructions here to do something when button IS pressed (1)
  INC $0203
  INC $0207
  INC $020B
  INC $020F
  INC $0203
  INC $0207
  INC $020B
  INC $020F
ReadRightDone:		; handling this button is done



  
  RTI             ; return from interrupt

;********** SUBROUTINES **********;

generatePrng:		; Pseudo Random Number Generator, probably not the best in the world
	LDA seed
	LDY #$E3
	ROL A
	STA rand
	ROL A
	TAX
	ADC rand,X
	RTS
	

spawnProjectile:


	LDX #$00			; Reset cooldown
	STX cooldown
	
	LDX $0207			; Get spaceship's top-left X coord, which is the closest to the middle of the ship
	DEX					; Decrease the coord 2 pixels, to alineate it in the center of the ship (the projectile is 4 pixels wide)
	DEX

	STX ballXAddr		; Store the coord as the ball's spawning X coord

	LDX #$00
	LDY nextPPUAddr
	CPY #$20
	BEQ resetPPUAddr
	JMP shootProj
	;BPL noProjectilePPUTooHigh
resetPPUAddr:
	LDY #$10
	STY nextPPUAddr
	
shootProj:
	LDA projectile, X	; load data from address (projectile + x)
	STA $0200, Y		; store into RAM address ($0200 + y)
	INY
	INX

	LDA projectile, X	; load data from address (projectile + x)
	STA $0200, Y		; store into RAM address ($0200 + y)
	INY
	INX
	
	LDA projectile, X	; load data from address (projectile + x)
	STA $0200, Y		; store into RAM address ($0200 + y)
	INY					; Only increase Y, because X isn't needed for loading the x coord of the projectile


	LDA ballXAddr
	STA $0200, Y
	INY					; Increase Y by one to store it on nextPPUAddr as the next available spot
	STY nextPPUAddr
	
	JMP ReadADone		; Return, projectile spawn done
	

	
noProjectile:
	JMP ReadADone		; Return


noProjectilePPUTooHigh:
	LDY #$10			; Reset nextPPUAddr to 10
	STY nextPPUAddr
	RTS

;;;;;;;;;;;;;;  
  
  
  
	.bank 1
	.org $E000
palette:
	.db $0F,$00,$00,$00,  $00,$00,$00,$00,  $00,$00,$00,$00,  $00,$00,$00,$00	; Background palette
	.db $0F,$00,$12,$21,  $0F,$17,$28,$39,  $00,$00,$00,$00,  $00,$00,$00,$00	; Sprite palette
	;	spaceship/proj.   meteor 

sprites:
	;   vert tile attr       horiz
	.db $D0, $00, %00000000, $80	;sprite 0
	.db $D0, $00, %01000000, $88	;sprite 1
	.db $D8, $10, %00000000, $80	;sprite 2
	.db $D8, $10, %01000000, $88	;sprite 3
	
projectile:
	.db $CA, $01, %00000000	 ; Here will go X
	
meteor:
	;	vert tile attr       horiz
	.db $10, $02, $00000001	 ; Here will go X
	
	;76543210
	;|||   ||
	;|||   ++- Color Palette of sprite.  Choose which set of 4 from the 16 colors to use
	;|||
	;||+------ Priority (0: in front of background; 1: behind background)
	;|+------- Flip sprite horizontally
	;+-------- Flip sprite vertically




	.org $FFFA		;First of the three vectors starts here
	.dw NMI			;When an NMI happens (once per frame if enabled) the 
					;processor will jump to the label NMI:
	.dw RESET		;When the processor first turns on or is reset, it will jump
					;to the label RESET:
	.dw 0			;External interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "chr.chr"	;Includes 8KB graphics file