/*
 *  0xFF padding for Zet BIOS
 *  Copyright (C) 2009  Zeus Gomez Marmolejo <zeus@aluzina.org>
 *
 *  This file is part of the Zet processor. This program is free software;
 *  you can redistribute it and/or modify it under the terms of the GNU 
 *  General Public License as published by the Free Software Foundation;
 *  either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

int main(int argc, char *argv[])
{
  int f = -1;
  int i, top;

  if (argc==2) top=atoi (argv[1]);
  else top = 1000000;

  for (i=0; i<top; i++)
    write (1, &f, 4);

  return 0;
}
