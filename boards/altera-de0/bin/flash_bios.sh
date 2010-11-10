#!/bin/bash

if [ "x$NIOS2EDS" == "x" ]
then
  echo '$NIOS2EDS environment var must be set with the directory of the NIOS2 EDS'
  exit 1
fi

if [ "x$QUARTUSDIR" == "x" ]
then
  echo '$QUARTUSDIR environment var must be set with the dir of QUARTUS II'
  exit 1
fi

SCRIPTDIR=$(pwd)/$(dirname $0)
BIOSDIR=$SCRIPTDIR/../../../src/bios

if [ ! -f "$BIOSDIR/bios.rom" ]
then
  echo 'bios.rom has not been built. Go to src/bios and type wmake.'
  exit 1
fi

. $NIOS2EDS/nios2_sdk_shell_bashrc
export PATH=$NIOS2EDS/bin:$PATH

cd $NIOS2EDS/bin
./bin2flash \
  --input=$BIOSDIR/bios.rom \
  --output=$BIOSDIR/bios.flash \
  --location=0x0

cat > /tmp/flash_bios.cdf <<END
JedecChain;
        FileRevision(JESD32A);
        DefaultMfr(6E);

        P ActionCode(Cfg)
                Device PartName(EP3C16F484) Path("$SCRIPTDIR/") File("flash_bios.sof") MfrSpec(OpMask(1));

ChainEnd;

AlteraBegin;
        ChainType(JTAG);
AlteraEnd;
END

$QUARTUSDIR/bin/quartus_pgm /tmp/flash_bios.cdf

./nios2-flash-programmer \
  --base=0x02400000 \
  $BIOSDIR/bios.flash

rm /tmp/flash_bios.cdf
