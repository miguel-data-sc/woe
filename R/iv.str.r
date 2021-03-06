#' Calculate Information Value for character or factor columns
#'
#' This function calculates information value for character or factor columns of data frame. 
#'
#' @param df data frame with at least two columns (predictor x and outcome y)
#' @param x column (character or factor) for which Information Value should be calculated
#' @param y column (integer) with binary outcome. y has to be a column in df data frame. It is suggested that y is factor with two levels "bad" and "good" If there are no levels good/bad than the following assumptions are applied - if y is integer, than 0=good and 1=bad. If y is factor than level 2 is assumed to mean bad and 1 good.
#' @param verbose Prints additional details when TRUE. Useful mainly for debugging.
#' @export
#' @examples
#' iv.str(german_data,"purpose","gb")
#' iv.str(german_data,"savings","gb")

iv.str <- function(df,x,y,sql=TRUE,verbose=FALSE) {
  if (!(class(df)=="data.frame")) {
    stop("Parameter df has to be a data frame.")
  } 
  if (!(is.character(df[, x]) || is.factor(df[, x]))) {
    stop(paste("Input is not a character or factor! Variable:", x))
    } 
  if (!(is.numeric(df[, y]) || is.factor(df[, y]))) {
    stop("Outcome is not a number nor factor!")
  } 
  if (length(unique(df[, y])) != 2) {
    if(verbose) paste(cat(unique(df[,y])),"\n")
    stop("Not a binary outcome")
    }
  if (!(all(sort(unique(df[, y])) == c(0,1))) && is.numeric(df[,y])) {
    stop("Numeric outcome has to be encoded as 0 (good) and 1 (bad). \n")
  }
  if (is.factor(df[,y]) && all(levels(df[,y])[order(levels(df[,y]))]==c("bad","good"))) {
    if (verbose) cat("Assuming good = level 'good' and bad = level 'bad' \n")
    total_1 <- sum(df[,y]=="bad")
    } else if (is.factor(df[,y])) {
    if (verbose) cat("Factor: Assuming bad = level 2 and good = level 1 \n")
    total_1 <- sum(as.integer(df[, y])-1)

    } else {
    if (verbose) cat("Numeric: Assuming bad = 1 and good = 0 \n")
    total_1 <-sum(df[, y])

  }

  # rename all missing rows to level missing

  df[,x] <- as.factor(ifelse(is.na(df[,x]),"missing",as.character(df[,x])))
  # df[,x] = factor(df[,x], levels=c(levels(df[,x]), "missing"))
  # df[,x][is.na(df[,x])] <- "missing"

  good <- bad <- NULL # This is needed to avoid NOTES about not visible binding from R CMD check
  
  total_0 <- nrow(df) - total_1  
  avg_bad_rate <- total_1 / (total_0+total_1)

  iv_data <- data.frame(unclass(table(df[, x],df[, y])))
  
  if (all(names(iv_data)==c("bad","good"))) {
    iv_data <- iv_data[,c(2,1)]
  }


  names(iv_data) <- c("good","bad")
  iv_data <-  within(iv_data, {
                class <- row.names(iv_data)
                variable <- x
                pct_bin <- (good+bad) / (total_0+total_1)
                bad_rate <- bad/(good+bad)
                inflation <- bad_rate / avg_bad_rate - 1
                pct_good <- good / total_0
                pct_bad <- bad / total_1
                odds <-  pct_bad / pct_good
                woe <- log(odds)
                miv <- (pct_bad - pct_good) * woe 
                sql <- paste('when ',variable,ifelse(class=='missing',' is ',' = "'),
                              ifelse(class=='missing','null', class),
                              ifelse(class=='missing',' then ','" then '),sep="")   
  })

  if(is.factor(df[,x])) {
    iv_data$class <- factor(iv_data$class,levels=levels(df[,x]))
  }  

  if(sql){
    iv_data <- iv_data[c("variable","class","pct_bin","good","bad","bad_rate","inflation","pct_good","pct_bad","odds","woe","miv","sql")]
    } else {
    iv_data <- iv_data[c("variable","class","pct_bin","good","bad","bad_rate","inflation","pct_good","pct_bad","odds","woe","miv")]
    }

  if(any(iv_data$good == 0) | any(iv_data$bad == 0)) {
    warning("Some group for outcome 0 has zero count. This will result in -Inf or Inf WOE. Replacing - ODDS=1, WoE=0, MIV=0. \n The bin is either too small or suspiciously predictive. \n You should fix this before running any model. It does not make any sense to keep WoE = 0 for such bin.")
      iv_data$woe <- ifelse(is.infinite(iv_data$woe),0,iv_data$woe)
      iv_data$miv <- ifelse(is.infinite(iv_data$miv),0,iv_data$miv)
      iv_data$odds <-ifelse(is.infinite(iv_data$odds),1,iv_data$odds)
  }
  
  rownames(iv_data) <- NULL
  #cat (paste("Information Value",round(sum(iv_data$miv),2),"\n"))
  iv_data
}

