# sql_to_html
Take a SQL query and turn it into HTML using PL/SQL.

## Instructions
There is currenly one function, `create table`, that takes a SQL query as a string and returns an HTML table.

```sql
FUNCTION sql_to_html.create_table(
	p_sql IN CLOB,
	p_add_header IN BOOLEAN DEFAULT TRUE,
	p_headers IN VARCHAR2 DEFAULT NULL,
	p_table_attribute IN VARCHAR2 DEFAULT NULL,
	p_header_attributes IN VARCHAR2 DEFAULT NULL,
	p_cell_attributes IN VARCHAR2 DEFAULT NULL,
	p_separator IN VARCHAR2 DEFAULT '|',
	p_escape_chars IN BOOLEAN DEFAULT TRUE ) RETURN CLOB
```

### Parameters
| Parameter | Description |
| --- | --- |
| `p_sql` | A `SELECT` query in string form. All values should be `VARCHAR2`s up to 4000 bytes long. Any other data type will be implicitly converted to a character string, possibly with unexpected results. Check your NLS settings or use `TO_CHAR` if you're going to be selecting dates! |
| `p_add_header` | If true, the first row will be column headers, as `<TH>`. If false, the table will start with `<TD>`s. |
| `p_headers` | If headers are enabled and this is null, the column headers will be the field names, as determined from the query. If this is not null, it should be a delimited string of header values. |
| `p_table_attribute` | This string of HTML attributes will be added to the `<TABLE>` element. For example, if `'id="foo" class="bar"'`, the resulting table will be `<TABLE id="foo" class="bar">`. |
| `p_header_attributes` |  A delimited string of HTML attributes to add to the `<TH>` elements. |
| `p_cell_attributes` | A delimeted string of HTML attributes to add to the `<TD>` elements. |
| `p_separator` | The default separator to use for `p_headers`, `p_header_attributes`, and `p_cell_attributes`. This must be a single character. The default is the pipe character (\|), since that is not likely to be used in an HTML attribute. |
| `p_escape_chars` | If true, HTML characters in the output will be escaped. This affects only the contents of the header and data cells; attributes are never escaped. |

### Example
```sql
sql_to_html.create_table( 
    p_sql => 'SELECT ''One fish'', 2, SYSDATE, ''I <3 you'' FROM dual' ,
    p_headers => 'Fish|Other Fish|Right Now|Heart',
    p_header_attributes => 'class="col1"|class="col2"',
    p_table_attribute => 'id="mytable" class="myclass"',
    p_cell_attributes => 'class="col1"|class="col2"|class="col3"' )
```
will output this HTML table (indentation added for clarity):
```html
<TABLE  id="mytable" class="myclass">
    <TR>
	    <TH class="col1">Fish</TH>
		<TH class="col2">Other Fish</TH>
		<TH>Right Now</TH>
		<TH>Heart</TH>
	</TR>
	<TR>
		<TD class="col1">One fish</TD>
		<TD class="col2">2</TD>
		<TD class="col3">2017-01-09 19:11:34</TD>
		<TD>I &lt;3 you</TD>
	</TR>
</TABLE>
```

## Installation
There is currently no installation script. Run the \*.pks and \*.pkb files in SQL*Plus, SQL Developer, or your IDE of choice. I suggest installing it into its own schema and granting execute privileges to any schema that needs to use it.

## Security 
This package uses `DBMS_SQL` to execute the SQL command and runs with `AUTHID CURRENT_USER` permissions. No checking of the SQL command is done, so you should make sure to protect it from SQL injection attacks.

Since the output is likely to be used on a web page, care should also be taken that the output is escaped to protect against HTML injection attacks.
