CREATE OR REPLACE PACKAGE BODY sql_to_html as
    
    TYPE attribs_tt IS TABLE OF VARCHAR2(4000);
    
    -- Breaks string into an array of tokens
    FUNCTION tokenize( p_str IN VARCHAR2, p_sep IN VARCHAR2 ) RETURN attribs_tt IS
        l_attrs         attribs_tt := attribs_tt();
        l_sep           VARCHAR2(2);
        i               INTEGER := 0;
        d varchar2(1000);
    BEGIN
        l_sep := p_sep;
        IF p_sep IN ( '\', '.', '^', '$', '|', '[', ']', '(', ')', '!', '?', '*', '+', '{', '}', '''' ) THEN
            l_sep := '\' || l_sep;
        END IF;
        
        l_attrs.EXTEND( REGEXP_COUNT( p_str, l_sep ) + 1 );
        FOR r IN ( SELECT REGEXP_SUBSTR( p_str, '(.*?)(' || l_sep || '|$)', 1, level, null, 1 ) 
                          AS token FROM dual
                   CONNECT BY level <= REGEXP_COUNT( p_str, l_sep ) + 1 )
        LOOP
            i := i + 1;
            l_attrs( i ) := r.token;
        END LOOP;
        
        RETURN l_attrs;
    END tokenize;


    -- Creates an HTML table from a SQL query.
    FUNCTION create_table (
        p_sql IN CLOB,
        p_add_header IN BOOLEAN DEFAULT TRUE,
        p_headers IN VARCHAR2 DEFAULT NULL,
        p_table_attribute IN VARCHAR2 DEFAULT NULL,
        p_header_attributes IN VARCHAR2 DEFAULT NULL,
        p_cell_attributes IN VARCHAR2 DEFAULT NULL,
        p_separator IN VARCHAR2 DEFAULT '|',
        p_escape_chars IN BOOLEAN DEFAULT TRUE
    ) RETURN CLOB IS
        c               INTEGER;
        dummy           INTEGER;
        
        l_headers       attribs_tt := attribs_tt();
        l_header_attr   attribs_tt := attribs_tt();
        l_cell_attr     attribs_tt := attribs_tt();
        l_col_count     INTEGER;
        l_row_count     INTEGER;
        l_col_desc      dbms_sql.desc_tab2;
        l_table         CLOB;
        l_varchar       VARCHAR2(4000 BYTE);
        
        
    
    BEGIN
        dbms_lob.createtemporary( l_table, TRUE );
        c := dbms_sql.open_cursor;
        dbms_sql.parse( c, p_sql, dbms_sql.NATIVE );
        dbms_sql.describe_columns2( c, l_col_count, l_col_desc );
        FOR i IN 1..l_col_count LOOP
            dbms_sql.define_column( c, i, l_varchar, 4000 );
        END LOOP;
        
        l_table := l_table || htf.tableopen( cattributes => p_table_attribute );
        
        IF p_add_header THEN
            IF p_header_attributes IS NOT NULL THEN
                l_header_attr := tokenize( p_header_attributes, p_separator );
            END IF;
            l_header_attr.EXTEND( l_col_count - l_header_attr.COUNT );
            
            IF p_headers IS NOT NULL THEN
                l_headers := tokenize( p_headers, p_separator );
                l_headers.EXTEND( l_col_count - l_headers.COUNT );
            ELSE
                l_headers.EXTEND( l_col_desc.COUNT );
                FOR i IN 1..l_col_desc.COUNT LOOP
                    l_headers( i ) := CASE WHEN p_escape_chars 
                        THEN htf.escape_sc( l_col_desc( i ).col_name ) 
                        ELSE l_col_desc( i ).col_name END;
                END LOOP;
            END IF;
            
            l_table := l_table || htf.tablerowopen;
            FOR i IN 1..l_headers.COUNT LOOP
                l_table := l_table || htf.tableheader( 
                    cvalue => CASE WHEN p_escape_chars 
                        THEN htf.escape_sc( l_headers( i )) 
                        ELSE l_headers( i ) END,
                    cattributes => l_header_attr( i ));
            END LOOP;
            l_table := l_table || htf.tablerowclose;
        END IF;
        
        IF p_cell_attributes IS NOT NULL THEN
            l_cell_attr := tokenize( p_cell_attributes, p_separator );
        END IF;
        l_cell_attr.EXTEND( l_col_count - l_cell_attr.COUNT );
        
        dummy := dbms_sql.execute( c );
        LOOP
            l_row_count := dbms_sql.fetch_rows( c );
            EXIT WHEN l_row_count = 0;
            FOR i IN 1..l_row_count LOOP
                l_table := l_table || htf.tablerowopen;
                
                FOR j IN 1..l_col_count LOOP
                    dbms_sql.column_value( c, j, l_varchar );
                    l_table := l_table || htf.tabledata(
                        cvalue => CASE WHEN p_escape_chars
                            THEN htf.escape_sc( l_varchar )
                            ELSE l_varchar END,
                        cattributes => l_cell_attr( j ));
                END LOOP;
                l_table := l_table || htf.tablerowclose;
            END LOOP;
        END LOOP;
        
        l_table := l_table || htf.tableclose;

        dbms_sql.close_cursor( c );
        RETURN l_table;
        
    EXCEPTION WHEN OTHERS THEN
        IF dbms_sql.is_open( c ) THEN
            dbms_sql.close_cursor( c );
        END IF;
        RAISE;
    END create_table;
    
END sql_to_html;
/
