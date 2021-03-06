library(lubridate)

#Params: term_list - list of strings
#Return: or - a single string of all in term_list seperated by +OR+

or_elastic <- function(term_list) {
  or <- "("
  term_list<-paste0('\\\"',term_list,'\\\"')
  
  for (i in 1:(length(term_list) - 1)) {
    or <- paste0(or, term_list[i], ' OR ')
  }
  or <- paste0(or, term_list[length(term_list)], ')')
  
  return(or)
}

or_together <- function(term_list) {
  or <- "("
  term_list<-paste0('\"',term_list,'\"')
  
  for (i in 1:(length(term_list) - 1)) {
    or <- paste0(or, term_list[i], '+OR+')
  }
  or <- paste0(or, term_list[length(term_list)], ')')
  
  return(or)
}


#escapes the following characters+ - && || ! ( ) { } [ ] ^ " ~ * ? : \ replaces spaces with %20%
#Params: string - a field that may contain a space "childrens advil"
#Return: string - same string with spaces replaced by %20% (used in lucene query string) "childrens%20%advil"
remove_spaces <- function(string) {
  string <- gsub("%", "%20", string)
  string <- gsub("'", "%27", string)
  #string <- gsub(",", "%20", string)
  #string <- gsub("-", "%20", string)
  #string <- gsub("\\/", "", string)
  string <- gsub("!", "", string)
  string <- gsub("&", "", string)
  string <- gsub(' ', '%20', string)
  
  first_char<-substr(string,1,1)
  
  if(first_char=="("){
    string <- string
  }else{
    string<-paste0('\"',string,'\"')
  }
  
  # # string <- gsub("\}", "\\}", string)
  # # string <- gsub("\[", "\\[", string)
  # # string <- gsub("\]", "\\]", string)
  # string <- gsub("^", "\\^", string)
  # string <- gsub("~", "\\~", string)
  # string <- gsub("*", "\\*", string)
  # string <- gsub("?", "\\?", string)
  # string <- gsub(":", "\\:", string)
  # string <- gsub("\\", "\\\\", string)
  
  string
  
}

#used for main plot of CVShiny
#Params: uri - a full uri for a lucene 
#Return: terms - a vector with three uris seperated by seriousness
add_term <- function(uri) {
  
  terms <- c(paste0(uri,"+AND+!death:true+AND+seriousness:Yes"), paste0(uri, "+AND+death:true"),  paste0(uri, "+AND+seriousness:No"))
  return (terms)
  
}

request <- function(search_uri) {
  
  
  r <- GET(search_uri)
  response <- content(r, "parsed")
  total <- response$total
  
  return(total)
}


request_listed <- function(uri_list) {
  
  totals <- lapply(uri_list, request)
  return(unlist(totals))
}

#Params:
#Return:
counter <- function(uri, count_term, key=''){
  search_uri <- paste0(uri, '&count=', count_term, key)
  r <- GET(search_uri)
  results<- content(r, 'parsed')$results
  
  df <- data.frame(category=sapply(results,`[[`,1),doc_count=sapply(results,`[[`,2), stringsAsFactors = FALSE)
  
  return(df)
}


#defaults are added so that function is reusible for counting (piecharts)
#Params:
#Return:
create_uri <- function(startDate, endDate, gender='All', age=c(0, 125),min_inclu=FALSE,max_inclu=FALSE, rxn=NULL, soc=NULL, drug_inv='Any', drugname=NULL, seriousness=NULL, search_type='', ...) {

  search_uri <- 'https://node.hres.ca/drug/event?search='
  
  #if smq is used in pt term selection:
  # if(any(grepl('(SMQ)',rxn))){
  # #extract all terms with (SMQ):
  # smq_rxn<-grep('(SMQ)',rxn,value=T)
  # 
  # smq_search<-sapply(smq_rxn,function(x){sprintf('{
  # "_source": "pt_name_eng",
  # "query": {"match": {"smq_name": {"query": "%s","operator": "and"}}}}',x)})
  # 
  # smq_pt<-lapply(smq_search,function(x){Search(index='meddra_pt',body=x,size=300)})
  # 
  # #extract all pt terms associated with smq term:
  # smq_pt_res<-list()
  # for (i in seq_along(smq_pt)){
  #   smq_pt_res[[i]]<-sapply(smq_pt[[i]]$hits$hits,"[[",c("_source"))%>%unlist(use.names=F)
  # }
  # 
  # smq_pt_res<-unlist(smq_pt_res,use.names = F)
  # 
  # #replace smq terms with pt terms:
  # rxn<-c(rxn,smq_pt_res)
  # rxn<-rxn[!grepl('(SMQ)',rxn)]%>%unique()
  # 
  # }else{
  #   rxn<-rxn
  # }
  
  
  if(any(grepl('(SMQ)',rxn))){
    #extract all terms with (SMQ):
    
    #define broad or narrow:
    broad_term<-grep('\\(SMQ\\)-Broad',rxn,value=T)
    broad_term<-gsub('-Broad','',broad_term)
    
    if(length(broad_term)==0){
      
      broad_rs<-NULL
    
    }else{
    
    if(length(broad_term)>1){
      broad_term<-or_elastic(broad_term)
    }else{
      broad_term<-paste0('\\\"',broad_term,'\\\"')
    }
    
      broad_query<-paste0('
                          {
                          "query":{
                          "query_string":{
                          "query":"smq_name:',broad_term,'"}
                          },
                          "aggs":{
                          "type_count":{
                          "terms":{
                          "field":"pt_name_eng.keyword",
                          "size":500
                          }
                          }
                          }
                          }')
  
      broad_rs<-Search(index='meddra_smq',body=broad_query,raw=T)%>%fromJSON()
      broad_rs<-broad_rs$aggregations$type_count$buckets$key
      
    }
    
    narrow_term<-grep('\\(SMQ\\)-Narrow',rxn,value=T)
    narrow_term<-gsub('-Narrow','',narrow_term)
    
    if(length(narrow_term)==0){
      
      narrow_rs<-NULL
    }else{
    
    if(length(narrow_term)>1){
      narrow_term<-or_elastic(narrow_term)
    }else{
      narrow_term<-paste0('\\\"',narrow_term,'\\\"')
    }
    
      narrow_query<-paste0('
                           {
                           "query":{
                           "query_string":{
                           "query":"smq_name:',narrow_term,' AND term_scope:2 "}
                           },
                           "aggs":{
                           "type_count":{
                           "terms":{
                           "field":"pt_name_eng.keyword",
                           "size":500
                           }
                           }
                           }
                           }')
    
    narrow_rs<-Search(index='meddra_smq',body=narrow_query,size=0,raw=T)%>%fromJSON()
    narrow_rs<-narrow_rs$aggregations$type_count$buckets$key
  }
  
  #replace smq terms with pt terms:
  rxn<-unique(c(rxn,broad_rs,narrow_rs))
  rxn<-rxn[!grepl('(SMQ)',rxn)]
  
}else{
  rxn<-rxn
}
  
  
  
  if(length(drugname) > 1) {
    drugname <- or_together(drugname)
  }
  
  if(length(rxn) > 1 ) {
    rxn <- or_together(rxn)
  }
  
  if(length(soc) > 1){
    soc <- or_together(soc)
  }

  
  #TODO add options for months
  # search_uri <- paste0(search_uri, 'datintreceived:[', toString(dateSequence), '+TO+', toString(dateSequence %m+% years(1)), ']')
  #if(age[1] != 0 & age[2] != 125) {
  search_uri <- paste0(search_uri, 'datintreceived:[', toString(startDate), '+TO+', toString(endDate), ']')
  

  if(age[1] != 0 | age[2] != 125) {
    
    if(!min_inclu & !max_inclu){
    search_uri <- paste0(search_uri, '+AND+patient_age_y:', '[', age[1], '+TO+', age[2], ']')
    }
    
    if(min_inclu & !max_inclu){
      search_uri <- paste0(search_uri, '+AND+patient_age_y:', '{', age[1], '+TO+', age[2], ']')
    } 
    
    if(!min_inclu& max_inclu){
      search_uri <- paste0(search_uri, '+AND+patient_age_y:', '[', age[1], '+TO+', age[2], '}')
    }
    
    if(min_inclu & max_inclu){
      search_uri <- paste0(search_uri, '+AND+patient_age_y:', '{', age[1], '+TO+', age[2], '}')
    }
  }
  

  if (gender != "All"){
    search_uri <- paste0(search_uri, '+AND+patient_gender:', gender)
  }

  if(!is.null(rxn)){
    search_uri <- paste0(search_uri, '+AND+reaction_pt.keyword:', remove_spaces(rxn))
  }
    

  if(!is.null(soc)) {
    search_uri <- paste0(search_uri, '+AND+reaction_soc.keyword:', remove_spaces(soc))
  }

  
if(!is.null(drugname)){
    
  if(drug_inv == 'Concomitant'){
    
    if(search_type== 'brand'){
      search_uri <- paste0(search_uri, '+AND+report_drugname_concomitant:', remove_spaces(drugname))
    }else{
      search_uri <- paste0(search_uri, '+AND+report_ingredient_concomitant:', remove_spaces(drugname))
    }
  }
  
  
  if(drug_inv=='Suspect'){
    if(search_type=='brand'){
      search_uri <- paste0(search_uri, '+AND+report_drugname_suspect:', remove_spaces(drugname))
    }else{
      search_uri <- paste0(search_uri, '+AND+report_ingredient_suspect:', remove_spaces(drugname))
    }
  }
  
  
  if(drug_inv=='Any'){
    if(search_type=='brand'){
      search_uri <- paste0(search_uri, '+AND+(report_drugname_suspect:', remove_spaces(drugname),'+OR+report_drugname_concomitant:',
                           remove_spaces(drugname),')')
    }else{
      search_uri <- paste0(search_uri, '+AND+(report_ingredient_suspect:', remove_spaces(drugname),'+OR+report_ingredient_concomitant:',
                           remove_spaces(drugname),')')
    }
  }
  
}
    
    
    

  if(!is.null(seriousness)){
    
    if(seriousness == 'Death') {
      search_uri <- paste0(search_uri, '+AND+death:true')
    }
    else if(seriousness == 'Serious(Excluding Death)') {
      search_uri <- paste0(search_uri, '+AND+!death:true+AND+seriousness:Yes')
    }
  }
  
  return (search_uri)
}


#gets all time chart dat, splits by year and seriousness
#Params: current_search params - could be refactored to take a list
#Return: 
get_timechart_data <- function(time_period,date_start,date_end, gender, age,min_age,max_age, rxn, soc, drug_inv, drugname, seriousness, name_type, ...){
  result <- list()
  
  
  for (i in 1:(length(date_start)- 1)){

        search_uri<- create_uri(date_start[i], date_end[i+1], gender, age,min_age,max_age, rxn, soc, drug_inv, drugname, seriousness, name_type)
        
    search_uri <- add_term(search_uri)
    result[[i]] <- search_uri
  }
  
  return(result)
}

#
#Params: startDate - where sequence should start(inclusive), endDate - where Sequence should end (inclusive), time_period - month or year to split sequence by
#Return: dateSequence - interval of dates by time period specified, used to loop over and create a list of uri's for main graph generation
get_date_sequence_start <- function(startDate, endDate, time_period) {
  
  start_seq <- floor_date(as.Date(startDate), time_period)
  
  if(time_period == 'year') {
    dateSequence <- seq(start_seq, as.Date(endDate) %m+% years(1), by=time_period)
  }
  else {
    dateSequence <- seq(start_seq, as.Date(endDate) %m+% months(1), by=time_period)
  }
  
  dateSequence[1] <- as.Date(startDate)
  dateSequence[length(dateSequence)] <- endDate
  
  return(dateSequence)
}

get_date_sequence_end <- function(startDate, endDate, time_period) {
  
  start_seq <- floor_date(as.Date(startDate), time_period)
  
  if(time_period == 'year') {
    dateSequence <- seq(start_seq, as.Date(endDate) %m+% years(1), by=time_period)-1
  }
  else {
    dateSequence <- seq(start_seq, as.Date(endDate) %m+% months(1), by=time_period)-1
  }
  
  dateSequence[1] <- as.Date(startDate)
  dateSequence[length(dateSequence)] <- endDate
  
  return(dateSequence)
}

#NANCY: 

#Params:
#Return:
parse_response <- function(uri){
  
  uri<-paste0(uri,'&limit=1000')
  response <- fromJSON(content(GET(uri), as='text'))$result
  return(response)
}

