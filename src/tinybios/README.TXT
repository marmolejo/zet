	tinyBIOS read.me			Pascal Dornier	010212
	----------------			pdornier@pcengines.com
	
	LICENSING:
	
	This code is licensed pursuant to the Common Public License rev. 0.5
	(see CPL0_5.HTM).
	
	Please provide bug fixes or additional features to me for inclusion
	in the code base. Contributing to the BIOS core gives you specific
	benefits - read the license for details.
	
	CHIPSET SUPPORT:
	
	Chipset modules available in open source:
	
	  ALI M1487
	  ALI M6117
	
	Chipset modules available for licensing from PC Engines:
	
	  ALI M1541 / M1543	(no AGP support)
	  AMD Elan SC400 / SC410
	  AMD Elan SC520
	  Intel 430TX
	  National SC1200	(no VSA support, requires native drivers)
	  National GXM		(no VSA support, requires native drivers)
	  STMicroelectronics STPC Client
	  STMicroelectronics STPC Consumer
	  STMicroelectronics STPC Industrial (incomplete)
	
	Chipset modules available from chip suppliers / third parties:
	
	  none so far - contact me to be included on this list
	
	Unless you make prior arrangements with me, chipset ports derived
	from open source chipset modules must be published as open source
	as well. Chip supplier NDA may be required for certain chipset
	modules.
	
	SUPPORT:
	
	This code is provided "as is", and I cannot provide free support.
	Prior versions of tinyBIOS have been used by many customers, with
	minimal support required. Contact me for a quote on customer
	specific support, adaptations etc.

	INSTALLATION:
	
	To assemble tinyBIOS, you need to buy the A386 assembler (www.eji.com).
	A linker is not required.
	
	The BIOS core files should be at the base of the tree, e.g. \TB.
	Tools should be in \TB\TOOL. Chipset modules should be subdirectories
	of \TB, e.g. \TB\ALI6117. Use the MAKE batch files in the chipset
	directories to build the BIOS.
	
	The source code was written using tab stops in columns 11, 19, 41.
	The editor built into AS.COM will handle this correctly. See
	TOOL\ED.DOC for details on how to use this editor.
	
