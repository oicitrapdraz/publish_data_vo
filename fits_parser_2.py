import sys
import json

from astropy.io import fits

def list_duplicates(seq):
  seen = set()
  seen_add = seen.add
  seen_twice = set(x for x in seq if x in seen or seen_add(x))

  return list(seen_twice)

if __name__ == '__main__':

    hdulist = fits.open(sys.argv[1])

    hdu_list = []

    for i in range(len(hdulist)):
        raw_keys = list(hdulist[i].header.keys())

        duplicates = list_duplicates(raw_keys)

        keys = [key for key in raw_keys if bool(key.strip()) and key not in duplicates]

        header = []

        if i != 0:
            columns = hdulist[i].columns.names

            units = set(hdulist[i].columns.units)
            units.discard('')

        for key in keys:
            val = str(hdulist[i].header[key]).strip()
            header.append(['{}: {}'.format(key, val), val])

        if (i == 0):
            hdu_list.append({'index': i, 'header': header})
        else:
            hdu_list.append({'index': i, 'header': header, 'columns': list(columns), 'units': list(units)})

        result = {'content': hdu_list}

    json.dump(result, sys.stdout)