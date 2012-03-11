#!/bin/bash

SCRIPTDIR=$(dirname $0)
BIOSDIR=$SCRIPTDIR/../../../src/bios

if [ ! -f "$BIOSDIR/bios.rom" ]
then
  echo 'bios.rom has not been built. Go to src/bios and type wmake.'
  exit 1
fi

bin2flash \
  --input=$BIOSDIR/bios.rom \
  --output=$BIOSDIR/bios.flash \
  --location=0x0

cat > /tmp/flash_bios.cdf <<END
JedecChain;
        FileRevision(JESD32A);
        DefaultMfr(6E);

        P ActionCode(Cfg)
                Device PartName(EP2C35F672) Path("$SCRIPTDIR/") File("flash_bios.sof") MfrSpec(OpMask(1));

ChainEnd;

AlteraBegin;
        ChainType(JTAG);
AlteraEnd;
END

$QUARTUS_ROOTDIR/bin/quartus_pgm /tmp/flash_bios.cdf

nios2-flash-programmer \
  --base=0x0 \
  $BIOSDIR/bios.flash

rm /tmp/flash_bios.cdf
