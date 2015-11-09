# yummy-spork
There are two scripts as a part of this reporsitory, xxx copies the files from your integration environment to a location in production & yyy performs a series of tasks to perform a rolling deployment. XXX is ran from your machine & it assumes that you already have yyy saved on the production VM.

xxx:
Copies The Build folder from integration to production server
Invokes remote script(YYY) on production server with parameters

yyy:
Takes these parameters:

