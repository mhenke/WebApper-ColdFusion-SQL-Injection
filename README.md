# readme

## Abstract

a script that would find and automatically cfqueryparam queries
 
## Blog Post

http://www.webapper.com/blog/index.php/2008/07/22/coldfusion-sql-injection

## Caveats

This will probably break some queries, especially if you do things like WHERE date > ‘#dateFormat(d)# #timeformat(d)#’ or WHERE NAME LIKE ‘#searchname#%’. USE WITH CAUTION! It’s best to test the changes before moving them into production. Remove the “.old” files once the site is confirmed as working well.

## License


## Git Workflow for Contributors

This project uses the excellent [Git Workflow series](http://www.silverwareconsulting.com/index.cfm/Git-Workflow) by [Bob Silverburg](https://github.com/bobsilverberg/) for contributions.

## Dealing with line endings

Before contributing, please read this [[http://help.github.com/dealing-with-lineendings/](http://help.github.com/dealing-with-lineendings/)](http://help.github.com/dealing-with-lineendings/)