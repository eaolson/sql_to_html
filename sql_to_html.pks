CREATE OR REPLACE PACKAGE sql_to_html 
AUTHID CURRENT_USER
AS

    -- Creates an HTML table from a SQL statement.
    FUNCTION create_table (
        p_sql IN CLOB,
        p_add_header IN BOOLEAN DEFAULT TRUE,
        p_headers IN VARCHAR2 DEFAULT NULL,
        p_table_attribute IN VARCHAR2 DEFAULT NULL,
        p_header_attributes IN VARCHAR2 DEFAULT NULL,
        p_cell_attributes IN VARCHAR2 DEFAULT NULL,
        p_separator IN VARCHAR2 DEFAULT '|',
        p_escape_chars IN BOOLEAN DEFAULT TRUE
    ) RETURN CLOB;
    
    -- TODO: create_table that takes a SYS_REFCURSOR instead of a string
    
END sql_to_html;
/