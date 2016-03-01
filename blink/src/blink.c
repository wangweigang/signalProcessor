/*
 ============================================================================
 Name        : blink.c
 Author      : Weigang
 Version     : 0.1
 Date		 : 2016.02.28
 Copyright   : Your copyright notice
 Description : coded in C, Ansi-style
 *
 * Usage: ./blink -dev xwin -geometry 600x300
 * Usage: ./blink -dev xterm -geometry 600x300
 ***********************************************************************
 * wiringPi: https://projects.drogon.net/raspberry-pi/wiringpi/
 *
 *    wiringPi is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU Lesser General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    wiringPi is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public License
 *    along with wiringPi.  If not, see <http://www.gnu.org/licenses/>.
 ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <plplot.h>
#include <wiringPi.h>

// wiringPI: LED Pin - wiringPi pin 0 is BCM_GPIO 17.
// wiringPI: LED Pin - wiringPi pin      physical pin
// wiringPI:                     06                07
// wiringPI:                     01                12
// wiringPI:                     04                16
// wiringPI:                     05                18
// wiringPI:                     07                29
// wiringPI:                     08                31
// wiringPI:                     09                32
// wiringPI:                     10                33
// wiringPI:                     12                35
// wiringPI:                     14                37  x
// wiringPI:                     13                36  x
// wiringPI:                     15                38  x
// wiringPI:                     16                40  x
#define	LED29	7
#define	LED31	8
#define	LED33	10
#define	LED35	12
#define	LED36	13
#define	LED37	14
#define	LED38	15
#define	LED40	16

// Plplot:  Variables for holding error return info from PLplot
static PLINT pl_errcode;
static char errmsg[160];

int main(int argc, const char *argv[]) {

	// Plplot: declare vars for pplot
	PLINT id1, n = 0, autoy, acc;
	PLFLT y[5] = {0.0, 0.0, 0.0, 0.0, 0.0 }, ymin, ymax, xlab, ylab;
	PLFLT yhold[5] = {0.0, 0.0, 0.0, 0.0, 0.0 };
	PLFLT t = 0.0, tmin, tmax, tjump;
	PLINT colbox, collab, colline[4], styline[4];
	const char *legline[4];
	char  driver[80] = "wxwidgets";    // xwin, xterm, wxwidgets, qtwidget
	char  geometry_master[] = "800x400+100+200";

	// wiringPI: declare vars for WiringPi
	int delay_ms = 40, i;
	unsigned int ledi[8] = { LED29, LED31, LED33, LED35, LED36, LED37, LED38, LED40 };

	if( argc == -2 ) {
		printf("Message: Graphic driver from command line: %s\n", argv[1]);
		strncpy(driver, argv[1], sizeof(driver));
		driver[sizeof(driver) - 1] = '\0';
	}

	// Plplot:  initialization
	// Plplot:  Parse and process command line arguments

	(void) plparseopts(&argc, argv, PL_PARSE_FULL);

	// Plplot:  Specify some reasonable defaults for ymin and ymax
	// Plplot:  The plot will grow automatically if needed (but not shrink)
	ymin  = -0.1;
	ymax  = 0.1;

	// Plplot:  Specify initial tmin and tmax -- this determines length of window.
	// Plplot:  Also specify maximum jump in t
	// Plplot:  This can accommodate adaptive timesteps
	tmin  = 0.;
	tmax  = (float) delay_ms * 1.0e-3 * 100.0;
	autoy = 1;       // autoscale y
	tjump = 0.01;    // 0.2 percentage of plot to jump
	acc   = 0;       // 1: accumulate;  0: scroll,

	/*  Plplot:
	    Color index of Plplot
		0	black (default background)
		1	red (default foreground)
		2	yellow
		3	green
		4	aquamarine
		5	pink
		6	wheat
		7	grey
		8	brown
		9	blue
		10	BlueViolet
		11	cyan
		12	turquoise
		13	magenta
		14	salmon
		15	white
	 Plplot: */

	// Plplot:  Axes options same as plbox.
	colbox     = 1;
	collab     = 15;
	colline[0] = 1;              // pens color and line style
	colline[1] = 1;
	colline[2] = 11;
	colline[3] = 11;
	styline[0] = 1;              // line style: only 2: solid(1) and dashed(>1) lines
	styline[1] = 1;
	styline[2] = 1;
	styline[3] = 1;

	legline[0] = "LED Red";   // pens legend
	legline[1] = "LED Red";
	legline[2] = "LED Blue";
	legline[3] = "LED Blue";

	xlab       = 0.01;            // legend position
	ylab       = 0.98;

	/*  Plplot:
	 Device index for Plplot
	 < 1> ps         PostScript File (monochrome)
	 < 2> psc        PostScript File (color)
	 < 3> xfig       Fig file
	 < 4> null       Null device
	 < 5> mem        User-supplied memory device
	 < 6> wxwidgets  wxWidgets Driver
	 < 7> svg        Scalable Vector Graphics (SVG 1.1)
	 < 8> bmpqt      Qt Windows bitmap driver
	 < 9> jpgqt      Qt jpg driver
	 <10> pngqt      Qt png driver
	 <11> ppmqt      Qt ppm driver
	 <12> tiffqt     Qt tiff driver
	 <13> svgqt      Qt SVG driver
	 <14> qtwidget   Qt Widget
	 <15> epsqt      Qt EPS driver
	 <16> pdfqt      Qt PDF driver
	 <17> extqt      External Qt driver
	 <18> memqt      Memory Qt driver
     Plplot: */
	printf("Message: Setup graphic driver.\n");
    plsdev(driver);         // which graphic driver

    // Plplot:  put some command line parameters here
    plsetopt( "geometry", geometry_master );

	// Plplot: plplot
	plinit();

	pladv(0);               // set to page 0
	plvsta();               // standard view

	// Plplot: Register our error variables with PLplot
	// Plplot: From here on, we're handling all errors here
	plsError(&pl_errcode, errmsg);


	plschr(0, 0.7);			// change font size

	// Plplot: setup and define a 4-line chart
	plstripc(&id1, "bcnst", "bcnstv", tmin, tmax, tjump, ymin, ymax, xlab, ylab,
			autoy, acc, colbox, collab, colline, styline, legline,
			"time [s]", "Voltage [v]", "LED Status");

	if (pl_errcode) {
		fprintf( stderr, "%s\n", errmsg);
		exit(1);
	}

	// Plplot: Let plplot handle errors from here on

	plsError(NULL, NULL);

	printf("Message: OrangePiPlus drives LEDs ... ...\n");

	wiringPiSetup();

	// wiringPI: set up pins as output
	for (i = 0; i < 8; i++) {
		pinMode(ledi[i], OUTPUT);
	}

	for (;;) {
		// do on-off forward
		for (i = 1; i < 8; i++) {
			digitalWrite(ledi[i], HIGH);	// On
			if (i < 5) {
				plstripa(id1, i-1, t, yhold[i]);
				y[i]     = (float) HIGH + (float)(i-1) * 1.1;
				plstripa(id1, i-1, t, y[i]);
				yhold[i] = y[i];
				t        = t + delay_ms*1.0e-3;
			}

			delay(delay_ms);				// mS

			digitalWrite(ledi[i], LOW);		// Off
			if (i < 5) {
				plstripa(id1, i-1, t, yhold[i]);
       			y[i]     = (float) LOW + (float)(i-1) * 1.1;
				plstripa(id1, i-1, t, y[i]);
				yhold[i] = y[i];
				t        = t + delay_ms*1.0e-3;
			}
		}

		// do on-off backwards
		// if (0)
		for (i = 6; i >= 0; i--) {
			digitalWrite(ledi[i], HIGH);	// On
			delay(delay_ms);				// mS
			digitalWrite(ledi[i], LOW);		// Off
		}

		//n++;
		if (0 && n > 0){
			printf("Reset and restart ... ...\n");
			n = 0;
			plstripd(id1);
			// plinit();
			// pladv(0);
			// plvsta();+
	 		plstripc(&id1, "bcnst", "bcnstv", tmin+t, tmax+t, tjump, ymin, ymax, xlab, ylab,
	 				autoy, acc, colbox, collab, colline, styline, legline,
					"time [s]", "Voltage [v]", "LED Status");
		}
	}

	// Plplot: Destroy strip chart and it's memory
	plstripd(id1);
	plend();

	return 0;
}
