import sys
import json

from astropy.io import fits

def get_metadata(hdulist, hdu_index):
	metadata = hdulist[hdu_index].header

	creator = ""
	instrument = ""
	facility = ""

	if ('OBSERVER' in hdulist[hdu_index].header):
		creator = hdulist[hdu_index].header['OBSERVER']
	elif ('AUTHOR' in hdulist[hdu_index].header):
		creator = hdulist[hdu_index].header['AUTHOR']

	if ('INSTRUME' in hdulist[hdu_index].header and 'TELESCOP' in hdulist[hdu_index].header):
		instrument = hdulist[hdu_index].header['INSTRUME'] + " " + hdulist[hdu_index].header['TELESCOP']
	elif ('INSTRUME' in hdulist[hdu_index].header):
		instrument = hdulist[hdu_index].header['INSTRUME']
	elif ('TELESCOP' in hdulist[hdu_index].header):
		instrument = hdulist[hdu_index].header['TELESCOP']
	elif ('CAMERA' in hdulist[hdu_index].header):
		instrument = hdulist[hdu_index].header['CAMERA']

	if ('ORIGIN' in hdulist[hdu_index].header):
		facility = hdulist[hdu_index].header['ORIGIN']

	result = {'creator': creator, 'instrument': instrument, 'facility': facility}

	return result	

if __name__ == '__main__':
	hdulist = fits.open(sys.argv[1])
	hdu_index = int(sys.argv[2])

	meta_meta = get_metadata(hdulist, 0)
	data_meta = get_metadata(hdulist, hdu_index)

	creator = ""
	instrument = ""
	facility = ""
	
	if data_meta['creator']:
		creator = data_meta['creator']
	elif meta_meta['creator']:
		creator = meta_meta['creator']

	if data_meta['instrument']:
		instrument = data_meta['instrument']
	elif meta_meta['instrument']:
		instrument = meta_meta['instrument']	

	if data_meta['facility']:
		facility = data_meta['facility']
	elif meta_meta['facility']:
		facility = meta_meta['facility']	

	result = {'creator': creator, 'instrument': instrument, 'facility': facility}

	json.dump(result, sys.stdout)