#include <stdio.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(int argc, char *argv[])
{
  char buf[4096];
  int  adr, n, fd, i;

  if (argc != 2) fprintf(stderr, "Syntax: %s tracefile\n",
                         argv[0]);

  fd=open(argv[1], O_RDONLY);
  if(fd < 0)
    {
      fprintf(stderr, "Error opening file\n");
      return 1;
    }

  while (1)
    {
      n=read(fd, &buf, 4096);

      for (i=2; i<n; i++)
        if ((buf[i] & 0xc0)==0xc0)
          {
            // hit
            adr = buf[i] & 0x3f;
            adr = (adr << 7) | (buf[i-1] & 0x7f);
            adr = (adr << 7) | (buf[i-2] & 0x7f);
            printf ("%05x\n", adr);
            i+=2;
          }

      if (i==n+1) lseek(fd, (off_t)(-1), SEEK_CUR);
      else if (i==n) lseek(fd, (off_t)(2), SEEK_CUR);

      if (n<4096) break;
    }

  return 0;
}
