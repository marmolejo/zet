.code16
start:
# Bring CKE high
# CSR_HPDMC_SYSTEM = HPDMC_SYSTEM_BYPASS|HPDMC_SYSTEM_RESET|HPDMC_SYSTEM_CKE;
movw $0xf200, %dx
movw $7, %ax
outw %ax, %dx

# Precharge All
# CSR_HPDMC_BYPASS = 0x400B;
movw $0xf202, %dx
movw $0x400b, %ax
outw %ax, %dx

# Auto refresh
# CSR_HPDMC_BYPASS = 0xD;
movw $0xd, %ax
outw %ax, %dx

# Auto refresh
# CSR_HPDMC_BYPASS = 0xD;
movw $0xd, %ax
outw %ax, %dx

# Load Mode Register, Enable DLL
# CSR_HPDMC_BYPASS = 0x23F;
movw $0x23f, %ax
outw %ax, %dx

movw $50, %cx
a: loop a

# Leave Bypass mode and bring up hardware controller
# CSR_HPDMC_SYSTEM = HPDMC_SYSTEM_CKE;
movw $0xf200, %dx
movw $4, %ax
outw %ax, %dx

movw $0, %ax
movw %ax, %ds

movw $0x1234, (0)
movw $0x5678, (2)

movw $0x9876, (0x2004)
hlt

.org 65520
jmp start

.org 65535
.byte 0xff
