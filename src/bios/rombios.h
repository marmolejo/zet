#define BIOS_PRINTF_HALT     1
#define BIOS_PRINTF_SCREEN   2
#define BIOS_PRINTF_INFO     4
#define BIOS_PRINTF_DEBUG    8
#define BIOS_PRINTF_ALL      (BIOS_PRINTF_SCREEN | BIOS_PRINTF_INFO)
#define BIOS_PRINTF_DEBHALT  (BIOS_PRINTF_SCREEN | BIOS_PRINTF_INFO | BIOS_PRINTF_HALT)

#define printf(format, p...)  bios_printf(BIOS_PRINTF_SCREEN, format, ##p)
#define BX_INFO(format, p...)   bios_printf(BIOS_PRINTF_INFO, format, ##p)
#define BX_PANIC(format, p...)  bios_printf(BIOS_PRINTF_DEBHALT, format, ##p)

#define FLASH_PAGE_REG			0xE000
#define EMS_PAGE1_REG			0x0208
#define EMS_PAGE2_REG			0x0209
#define EMS_PAGE3_REG			0x020A
#define EMS_PAGE4_REG			0x020B

#define EMS_ENABLE_REG			0x020C
#define EMS_ENABLE_VAL			0x8B			// The B Corresonds to the B in the EMS_SECTOR_OFFSET
#define EMS_SECTOR_OFFSET		0xB000		// Value of the offset register for the base of EMS

#define SECTOR_SIZE				512
#define SECTOR_COUNT				2880
#define RAM_DISK_BASE			68				// Must be a multiple of 4. This means start the RAM Disk at 0x110000	i.e one byte beyond the A20 addressing range of the 8086

#define DRIVE_A					0x00
#define DRIVE_B					0x01
#define DRIVE_C					0x80
#define DRIVE_D					0x81

#define HD_CYLINDERS  8322 // For a 4 Gb SD card
#define HD_HEADS      16
#define HD_SECTORS    63
