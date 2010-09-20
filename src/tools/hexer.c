//---------------------------------------------------------------------------
// This utility simply takes any binary file and turns it into a HEX file
// with no carriage returns or line feeds.
//---------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h> 

//---------------------------------------------------------------------------
static void MakeHEX(char *infile, char *outfile)
{
    FILE *fi, *fo;
    int  d, n;
    char data[8];

    fi = fopen(infile,  "rb");
    if(fi == NULL){
        fprintf(stderr, "Cannot open input file\n");
        exit(EXIT_FAILURE);        // terminate program early if can not open the file
    } 

    fo = fopen(outfile, "wt");
    if(fo == NULL){
        fprintf(stderr, "Cannot open output file\n");
        exit(EXIT_FAILURE);        // terminate program early
    } 

    n = 0;
    do {
        d = fgetc(fi);
        if(d == EOF) break;
        sprintf(data, "%02x", (unsigned char)d);
        fputc(data[0],fo);
        fputc(data[1],fo);
        n++;
    } while(d != EOF);

    fprintf(stderr, "%d bytes read and converted\n", n);
   
    fclose(fi);
    fclose(fo);
}
//---------------------------------------------------------------------------
static char *filename_ext(char *infile)
{
    char ext[] = "hex";
    static char fixed_filename[255];
    int i, dot;
    dot = 0;
    i   = 0;
    while(*infile) {
        if(*infile == '.') dot = i;
        fixed_filename[i++] = *infile++;
    }
    dot++;  
    for(i = 0; i < 4; i++) fixed_filename[i+dot] = ext[i];
    return &fixed_filename[0];    
}

//---------------------------------------------------------------------------
int main(int argc, char* argv[])
{
    char *infile  = argv[1];
    char *outfile = filename_ext(infile);
    
    fprintf(stderr, "Hexer Conversion Utility:\n");
    fprintf(stderr, "input  file = %s\n", infile);
    fprintf(stderr, "output file = %s\n", outfile);

    MakeHEX(infile, outfile);

    fprintf(stderr, "Conversion to HEX complete\n");
    return(EXIT_SUCCESS);
}
//---------------------------------------------------------------------------

