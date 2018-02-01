# Cuando ejecutemos 'rake db:seed'
# 1. Eliminamos todos los registros
# 2. Reseteamos todos los campos id
# 3. creamos los valores por defecto de nuevo

if ActiveRecord::Base.connection.table_exists? 'metadata_types'
	MetadataType.delete_all
	ActiveRecord::Base.connection.execute('TRUNCATE TABLE metadata_types RESTART IDENTITY')
end

if ActiveRecord::Base.connection.table_exists? 'metadata_coverage_wavebands'
	MetadataCoverageWaveband.delete_all
	ActiveRecord::Base.connection.execute('TRUNCATE TABLE metadata_coverage_wavebands RESTART IDENTITY')
end

MetadataType.create([
	{ name: 'Archive' },
	{ name: 'Bibliography' },
	{ name: 'Catalog' },
	{ name: 'Journal' },
	{ name: 'Library' },
	{ name: 'Simulation' },
	{ name: 'Survey' },
	{ name: 'Transformation' },
	{ name: 'Education' },
	{ name: 'Outreach' },
	{ name: 'EPOResource' },
	{ name: 'Animation' },
	{ name: 'Artwork' },
	{ name: 'Background' },
	{ name: 'BasicData' },
	{ name: 'Historical' },
	{ name: 'Photographic' },
	{ name: 'Press' },
	{ name: 'Organisation' },
	{ name: 'Project' },
	{ name: 'Registry' }
])

MetadataCoverageWaveband.create([
	{ name: 'One of Radio' },
	{ name: 'Millimeter' },
	{ name: 'Infrared' },
	{ name: 'Optical' },
	{ name: 'UV' },
	{ name: 'EUV' },
	{ name: 'Xray' },
	{ name: 'Gammaray' }
])