# cvapps

![](https://github.com/hres/cvapps/blob/master/Shinyapp_snapshot.png)

This app has been developed by the Data Sciences Unit of RMOD at Health Canada as part of the Open Data Initiative. This is a prototype experiment that utilizes publically available data (Canada Vigilance Adverse Reaction Online Database), and provide visualizations in an interactive format. Health Canada collects and maintains a high volume of adverse event reports associated with different drugs and products. This app allows users to effortlessly interact with the reports database, conduct searches and view results in highly interactive dashboards. To support innovation, coordination and to support Canadians, this interface permits the users to export search results (with no limitation to the number of rows) in various file formats such as CSV and Excel for further exploration and experimentation.


## App versions
Under [apps folder](apps) , there are 3 versions of cvapps.

[CVShiny_api](apps/CVShiny_api): This is the CVShiny version that is currently hosted on shiny server and available for distribution within Health Canada. This version reads data from Health Canada drug/event API.https://node.hres.ca/docs.html#drug-event-docs

[CVShiny_elastic](apps/CVShiny_elastic): This version of CVShiny connects directly to elasticsearch database that powers API. This version was initially built to address the issue that node.js occasionally shuts down. By connecting direclty to elasticsearch database, this version is more reliable, however it is not applicable to a public version

[CVShiny_smq](apps/CVSlhiny_elastic): This version of CVShiny was developed to specifically address SMQ hierarchy problem. This version allows the users to select SQM based on broad and narrow terms. Furhter development intends to extend to SMQ algorithmic term as well

## Data model

#### Schema: current
Tables were originally stored on a Postgrel relational database. The data were transformed into JSON objects and indexed in Elasticsearch.

#### Schema: meddra

Tables: Dynamically named table based on latest version in the history table of the date_refresh table. Version 20.1 will have a table name v_21_0.
Columns contain [meddra](https://www.canada.ca/en/health-canada/services/drugs-health-products/medeffect-canada/adverse-reaction-database/about-medical-dictionary-regulatory-activities-canada-vigilance-adverse-reaction-online-database.html) hierarchy, a controlled vocabulary of medical terms for regulatory purposes.


## Development

- [global.R](apps/CVShiny_api/global.R) is only run once, when the application is first hosted. This file runs all the database queries and generates the lists of search terms. The data is shared across user sessions.

- [server.R](apps/CVShiny_api/server.R) filters reports data to get a list of report_ids that map to the specified search terms. 


- [ui.R](apps/CVShiny_api/ui.R) passes search terms to backend and specifies layout of application. linechart.R formats data for linechartbindings.js, which has functions for the [nvd3](http://nvd3.org/index.html) javascript library.
         

## Apps ([apps](https://shiny.hres.ca/CVShiny)) 
(The link only works within Health Canada network)
> Health Canada data -> Elasticsearch -> API -> R Shiny

These are used for exploring and analyzing the data.
