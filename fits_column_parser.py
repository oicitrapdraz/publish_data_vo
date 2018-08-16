import sys
import json

from astropy.io import fits

if __name__ == '__main__':
	hdulist = fits.open(sys.argv[1])
	hdu_index = int(sys.argv[2])

	columns = hdulist[hdu_index].columns.names
	units = hdulist[hdu_index].columns.units
	formats = hdulist[hdu_index].columns.formats

	ucds = []
	comments = []

	for i in range(len(columns)):
		ucd_key = "TBUCD{}".format(i + 1)
		ucd_key_2 = "UCD__{}".format(i + 1)

		if (ucd_key in hdulist[hdu_index].header):
			ucds.append(hdulist[hdu_index].header[ucd_key])
		elif (ucd_key_2 in hdulist[hdu_index].header):
			ucds.append(hdulist[hdu_index].header[ucd_key_2])
		else:
			ucds.append("")

		comment_key = "TCOMM{}".format(i + 1)

		if (comment_key in hdulist[hdu_index].header):
			comments.append(hdulist[hdu_index].header[comment_key])
		else:
			comments.append("")

		format_cleaned = ''.join([x for x in formats[i] if not x.isdigit()])

		if (format_cleaned == 'D'):
			formats[i] = 'double precision'
		elif (format_cleaned == 'E'):
			formats[i] = 'real'
		elif (format_cleaned == 'J'):
			formats[i] = 'integer'
		elif (format_cleaned == 'I'):
			formats[i] = 'smallint'
		elif (formats[i] == 'A'):
			formats[i] = 'char'
		else:
			formats[i] = 'text'

	result = {'index': hdu_index, 'columns': list(columns), 'comments': comments, 'formats': formats, 'units': list(units), 'ucds': ucds}

	json.dump(result, sys.stdout)