import os
import urllib
import datetime
import csv
import unicodecsv

def daterange(start, stop, step_days=1):
	current = start
	step = datetime.timedelta(step_days)
	if step_days > 0:
		while current < stop:
			yield current
			current += step
	elif step_days < 0:
		while current > stop:
			yield current
			current += step
	else:
		raise ValueError("daterange() step_days argument must not be zero")



date_format = '%Y-%m-%d'
step = 1
DOWNLOADS_DIR = './cache'
year = 2015
url = "http://earthquake.usgs.gov/fdsnws/event/1/query?format=csv&starttime={0}T00:00:00&minmagnitude=0.1&format=csv&endtime={1}T23:59:59&maxmagnitude=10&orderby=time-asc"

startRange = datetime.date(year, 1, 1)
endRange = datetime.date(year+1, 1, 1)
today = datetime.date.today()

for i in daterange(startRange, endRange, step):
	start = i.strftime(date_format)
	end = (i+datetime.timedelta(days=step-1)).strftime(date_format)
	query = os.path.join(DOWNLOADS_DIR, start + "_" + end + ".csv")

	if ((i+datetime.timedelta(days=step-1)) <= today):
		try:
			if not os.path.isfile(query):
				urllib.urlretrieve(url.format(start, end), query)
				print ("Downloading results for " + start + " to " + end)
		except Exception as ex:
			print ("Could not download for " + start + " to " + end)
			print (ex)




with open('../processing/FaultTrace/data/quakes-' + str(year) + '.csv', 'wb') as result:
	a = unicodecsv.writer(result, encoding='utf-8')
	i = 0
	result.write("time,latitude,longitude,depth,mag,dmin,rms\r\n")

	for i in daterange(startRange, endRange, step):
		start = i.strftime(date_format)
		end = (i+datetime.timedelta(days=step-1)).strftime(date_format)
		query = os.path.join(DOWNLOADS_DIR, start + "_" + end + ".csv")

		if ((i+datetime.timedelta(days=step-1)) <= today):

			with open(query, "rb") as source:
				rdr = csv.reader( source )
				wtr = csv.writer( result )
				next(rdr)
				print(query)
				for row in rdr:
					wtr.writerow( (row[0], row[1], row[2], row[3], row[4], row[8], row[9]) )
