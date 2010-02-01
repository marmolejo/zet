#!/bin/bash
sed "s/\`git describe\`/$(git describe)/g" Makefile |
  sed "s/\`git log.\+\`/$(git log -1 | grep Date | sed 's/Date:   //g')/g" > Makefile.tmp
mv Makefile.tmp Makefile
