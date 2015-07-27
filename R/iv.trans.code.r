#' Output SQL transformation code 
#' Only output the vars you need


iv.trans.code <- function(vars,woe,bin) {
  
  if (!is.null(woe)) {
    iv_df <- rbind.fill(woe)
    
    for (n in vars) { 
      
      if(grepl("_woe",n))
      {  
        sqlstr <- paste("case",paste(iv_df[iv_df$variable==substr(n,1,nchar(n)-4),]$sql_code,collapse= "\n"),"end as",n,",\n\n")
        sink('transformation_code.txt',append=TRUE)
        cat(sqlstr)
        sink()
      } 
    }
  }
  
  if (!is.null(bin)) {
    iv_df <- rbind.fill(bin)
    
    for (n in vars) { 
      
      if(!grepl("_woe",n)) {
        
        sqlstr <- paste(paste(iv_df[grepl(as.character(n),iv_df$sql_code),]$sql_code,collapse= "\n"),"\n")
        
        sink('transformation_code.txt',append=TRUE)
        cat(sqlstr)
        sink()
      }
    }
  } 
}


