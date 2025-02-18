#!/usr/bin/env python
#******************************************************************************
# 
#  Project:  2009 Web Map Server Benchmarking
#  Purpose:  Generate WMS BBOX/size requests randomly over a defined dataset.
#  Author:   Frank Warmerdam, warmerdam@pobox.com
# 
#******************************************************************************
#  Copyright (c) 2009, Frank Warmerdam
# 
#  Permission is hereby granted, free of charge, to any person obtaining a
#  copy of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
# 
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
# 
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#  DEALINGS IN THE SOFTWARE.
#******************************************************************************

import random
import math
import string
import sys

# =============================================================================
def Usage():
    print 'Usage: wms_request.py [-count n] [-region minx miny maxx maxy]'
    print '                    [-minres minres] [-maxres maxres] '
    print '                    [-maxsize width height] [-minsize width height]'
    sys.exit(1)

# =============================================================================

if __name__ == '__main__':

    region = None
    minres = None
    maxres = None
    count = 1000
    minsize = (128,128)
    maxsize = (1024,768)

    # Parse command line arguments.
    argv = sys.argv
    
    i = 1
    while i < len(argv):
        arg = argv[i]

        if arg == '-wkt' or arg == '-pretty_wkt' or arg == '-proj4' \
           or arg == '-postgis' or arg == '-xml':
            output_format = arg

        elif arg == '-region' and i < len(argv)-4:
            region = (float(argv[i+1]),float(argv[i+2]),
                      float(argv[i+3]),float(argv[i+4]))
            i = i + 4

        elif arg == '-minsize' and i < len(argv)-2:
            minsize = (int(argv[i+1]),int(argv[i+2]))
            i = i + 2

        elif arg == '-maxsize' and i < len(argv)-2:
            maxsize = (int(argv[i+1]),int(argv[i+2]))
            i = i + 2

        elif arg == '-minres' and i < len(argv)-1:
            minres = float(argv[i+1])
            i = i + 1

        elif arg == '-maxres' and i < len(argv)-1:
            maxres = float(argv[i+1])
            i = i + 1

        elif arg == '-count' and i < len(argv)-1:
            count = int(argv[i+1])
            i = i + 1

        else:
            print 'Unable to process: %s' % arg
            Usage()

        i = i + 1

    if region is None:
        print '-region is required.'
        Usage()

    if minres is None:
        print '-minres is required.'
        Usage()
            
    if maxres is None:
        print '-maxres is required.'
        Usage()
            
    # -------------------------------------------------------------------------

    while count > 0:
        width = random.randint(minsize[0],maxsize[0])
        height = random.randint(minsize[1],maxsize[1])

        center_x = random.random() * (region[2] - region[0]) + region[0]
        center_y = random.random() * (region[3] - region[1]) + region[1]

        max_log10 = math.log10(maxres)
        min_log10 = math.log10(minres)
        random_log = random.random() * (max_log10 - min_log10)  + min_log10
        res = math.pow(10,random_log)

        bbox = (center_x - width*0.5*res,
                center_y - height*0.5*res,
                center_x + width*0.5*res,
                center_y + height*0.5*res)

        if bbox[0] >= region[0] \
           and bbox[1] >= region[1] \
           and bbox[2] <= region[2] \
           and bbox[3] <= region[3]:

            count = count-1
            print '%d;%d;%.8g,%.8g,%.8g,%.8g' \
                  % (width,height,bbox[0],bbox[1],bbox[2],bbox[3])
