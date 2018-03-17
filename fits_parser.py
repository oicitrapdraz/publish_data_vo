import sys
import json

from astropy.io import fits

if __name__ == '__main__':
    hdulist = fits.open(sys.argv[1])

    hdu_list = []

    for i in range(len(hdulist)):
        keys = set(list(hdulist[i].header.keys()))

        hdu = []

        for key in keys:
            val = hdulist[i].header[key]
            if (isinstance(val, str) and '\n' not in val):
                hdu.append(['{}: {}'.format(key, val), val])

        hdu_list.append({'index': i, 'content': hdu})

    result = {'hdu': hdu_list}

    json.dump(result, sys.stdout)
