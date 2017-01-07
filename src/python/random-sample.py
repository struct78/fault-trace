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


step = 7
date_format = '%Y-%m-%d'
DOWNLOADS_DIR = './cache'
startRange = datetime.date(2014, 12, 29)
endRange = datetime.date(2015, 12, 31)




with open('../processing/poseidon/data/quakes-sample.csv', 'wb') as result:
	a = unicodecsv.writer(result, encoding='utf-8')
	i = 0
	result.write("time,latitude,longitude,depth,mag,dmin,rms\r\n")

	for i in daterange(startRange, endRange, step):
		start = i.strftime(date_format)
		end = (i+datetime.timedelta(days=step-1)).strftime(date_format)
		query = os.path.join(DOWNLOADS_DIR, start + "_" + end + ".csv")
		previousDate = None
		x = 0
		with open(query, "rb") as source:
			rdr = csv.reader( source )
			wtr = csv.writer( result )
			next(rdr)
			for row in rdr:
				if (x > 20):
				#currentDate = datetime.datetime.strptime( row[0], "%Y-%m-%dT%H:%M:%S.%fZ" )
				#if (previousDate):
				#	if (previousDate.date() < currentDate.date()):
					wtr.writerow( (row[0], row[1], row[2], row[3], row[4], row[8], row[9]) )
					x = 0

				x += 1
				#previousDate = datetime.datetime.strptime( row[0], "%Y-%m-%dT%H:%M:%S.%fZ" )
