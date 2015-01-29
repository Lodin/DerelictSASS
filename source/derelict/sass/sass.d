﻿/*

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

*/

module derelict.sass.sass;

private {
    import derelict.util.loader;
    import derelict.util.exception;
    import derelict.util.system;

    static if( Derelict_OS_Windows ) {
        enum libNames = "libsass.dll";
    } else static if( Derelict_OS_Posix ) {
        enum libNames = "libsass.so,/usr/local/lib/libsass.so";
    } else {
        static assert( 0, "Need to implement libsass libNames for this operating system." );
    }
}

alias Sass_Output_Style = int;
enum : Sass_Output_Style {
    SASS_STYLE_NESTED = 0,
    SASS_STYLE_EXPANDED = 1,
    SASS_STYLE_COMPACT = 2,
    SASS_STYLE_COMPRESSED = 3,
}

alias Sass_Compiler_State = int;
enum : Sass_Compiler_State {
    SASS_COMPILER_CREATED,
    SASS_COMPILER_PARSED,
    SASS_COMPILER_EXECUTED
};

enum {
    SASS2SCSS_PRETTIFY_0 = 0,
    SASS2SCSS_PRETTIFY_1 = 1,
    SASS2SCSS_PRETTIFY_2 = 2,
    SASS2SCSS_PRETTIFY_3 = 3,
    
    SASS2SCSS_KEEP_COMMENT = 32,
    SASS2SCSS_STRIP_COMMENT = 64,
    SASS2SCSS_CONVERT_COMMENT = 128,
}

alias Sass_Tag = int;
enum : Sass_Tag {
    SASS_BOOLEAN,
    SASS_NUMBER,
    SASS_COLOR,
    SASS_STRING,
    SASS_LIST,
    SASS_MAP,
    SASS_NULL,
    SASS_ERROR
}

alias Sass_Separator = int;
enum : Sass_Separator {
    SASS_COMMA,
    SASS_SPACE
}

// Input behaviours
enum Sass_Input_Style {
    SASS_CONTEXT_NULL,
    SASS_CONTEXT_FILE,
    SASS_CONTEXT_DATA,
    SASS_CONTEXT_FOLDER
};

struct string_list {
    string_list* next;
    char* string;
}

private mixin template Sass_Options_Impl() {
    int precision;
    Sass_Output_Style output_style;
    bool source_comments;
    bool source_map_embed;
    bool source_map_contents;
    bool omit_source_map_url;
    bool is_indented_syntax_src;
    char* input_path;
    char* output_path;
    const(char)* indent;
    const(char)* linefeed;
    char* image_path;
    char* include_path;
    string_list* include_paths;
    char* source_map_file;
    Sass_C_Function_List c_functions;
    Sass_C_Import_Callback importer;
}

struct Sass_Options {
    mixin Sass_Options_Impl;    
};

private mixin template Sass_Context_Impl() {
    mixin Sass_Options_Impl;
    
    Sass_Input_Style type;
    char* output_string;
    char* source_map_string;
    int error_status;
    char* error_json;
    char* error_message;
    char* error_file;
    size_t error_line;
    size_t error_column;
    char** included_files;
}

struct Sass_Context {
    mixin Sass_Context_Impl;
}

struct Sass_File_Context  {
    mixin Sass_Context_Impl;
}

struct Sass_Data_Context {
    mixin Sass_Context_Impl;

    char* source_string;
}

struct Sass_Compiler {
    Sass_Compiler_State state;
    Sass_Context* c_ctx;
    void* cpp_ctx;
    void* root;
}

struct Sass_Import {
    char* path;
    char* base;
    char* source;
    char* srcmap;
}

struct Sass_C_Import_Descriptor {
    Sass_C_Import_Fn function_;
    void* cookie;
}

struct Sass_C_Function_Descriptor {
    const(char)* signature;
    Sass_C_Function function_;
    void* cookie;
}

union Sass_Value {
    Sass_Unknown unknown;
    Sass_Boolean boolean;
    Sass_Number number;
    Sass_Color color;
    Sass_String string;
    Sass_List list;
    Sass_Map map;
    Sass_Null null_;
    Sass_Error error;
}

struct Sass_Unknown {
    Sass_Tag tag;
}

struct Sass_Boolean {
    Sass_Tag tag;
    bool value;
}

struct Sass_Number {
    Sass_Tag tag;
    double value;
    char* unit;
}

struct Sass_Color {
    Sass_Tag tag;
    double r;
    double g;
    double b;
    double a;
}

struct Sass_String {
    Sass_Tag tag;
    char* value;
}

struct Sass_List {
    Sass_Tag tag;
    Sass_Separator separator;
    size_t length;
    Sass_Value** values;
}

struct Sass_Map {
    Sass_Tag tag;
    size_t length;
    Sass_MapPair* pairs;
}

struct Sass_Null {
    Sass_Tag tag;
}

struct Sass_Error {
    Sass_Tag tag;
    char* message;
}

struct Sass_MapPair {
    Sass_Value* key;
    Sass_Value* value;
}

extern( C ) @nogc nothrow {
    alias Sass_C_Function_List = Sass_C_Function_Descriptor* function ();
    alias Sass_C_Function = Sass_Value* function( Sass_Value*, void* cookie );
    alias Sass_C_Import_Fn = Sass_Import** function( const(char)* url, const(char)* prev, void* cookie);
    alias Sass_C_Import_Callback = Sass_C_Import_Descriptor function();
}

extern( C ) @nogc nothrow {
    alias da_sass_make_options = Sass_Options* function();
    alias da_sass_make_file_context = Sass_File_Context* function( const(char)* input_path );
    alias da_sass_make_data_context = Sass_Data_Context* function( char* source_string );

    alias da_sass_compile_file_context = int function( Sass_File_Context* ctx );
    alias da_sass_compile_data_context = int function( Sass_Data_Context* ctx );

    alias da_sass_make_file_compiler = Sass_Compiler* function( Sass_File_Context* file_ctx );
    alias da_sass_make_data_compiler = Sass_Compiler* function( Sass_Data_Context* data_ctx );

    alias da_sass_compiler_parse = int function( Sass_Compiler* compiler );
    alias da_sass_compiler_execute = int function( Sass_Compiler* compiler );

    alias da_sass_delete_compiler = void function( Sass_Compiler* compiler );

    alias da_sass_delete_file_context = void function( Sass_File_Context* ctx );
    alias da_sass_delete_data_context = void function( Sass_Data_Context* ctx );

    alias da_sass_file_context_get_context = Sass_Context* function( Sass_File_Context* file_ctx );
    alias da_sass_data_context_get_context = Sass_Context* function( Sass_Data_Context* data_ctx );

    alias da_sass_context_get_options = Sass_Options* function( Sass_Context* ctx );
    alias da_sass_file_context_get_options = Sass_Options* function( Sass_File_Context* file_ctx );
    alias da_sass_data_context_get_options = Sass_Options* function( Sass_Data_Context* data_ctx );
    alias da_sass_file_context_set_options = void function( Sass_File_Context* file_ctx, Sass_Options* opt );
    alias da_sass_data_context_set_options = void function( Sass_Data_Context* data_ctx, Sass_Options* opt );

    alias da_sass_option_get_precision = int function( Sass_Options* options );
    alias da_sass_option_get_output_style = Sass_Output_Style function( Sass_Options* options );
    alias da_sass_option_get_source_comments = bool function( Sass_Options* options );
    alias da_sass_option_get_source_map_embed = bool function( Sass_Options* options );
    alias da_sass_option_get_source_map_contents = bool function( Sass_Options* options );
    alias da_sass_option_get_omit_source_map_url = bool function( Sass_Options* options );
    alias da_sass_option_get_is_indented_syntax_src = bool function( Sass_Options* options );
    alias da_sass_option_get_indent = const(char)* function( Sass_Options* options );
    alias da_sass_option_get_linefeed = const(char)* function( Sass_Options* options );
    alias da_sass_option_get_input_path = const(char)* function( Sass_Options* options );
    alias da_sass_option_get_output_path = const(char)* function( Sass_Options* options );
    alias da_sass_option_get_image_path = const(char)* function( Sass_Options* options );
    alias da_sass_option_get_include_path = const(char)* function( Sass_Options* options );
    alias da_sass_option_get_source_map_file = const(char)* function( Sass_Options* options );
    alias da_sass_option_get_c_functions = Sass_C_Function_List function( Sass_Options* options );
    alias da_sass_option_get_importer = Sass_C_Import_Callback function( Sass_Options* options );

    alias da_sass_option_set_precision = void function( Sass_Options* options, int precision );
    alias da_sass_option_set_output_style = void function( Sass_Options* options, Sass_Output_Style output_style );
    alias da_sass_option_set_source_comments = void function( Sass_Options* options, bool source_comments );
    alias da_sass_option_set_source_map_embed = void function( Sass_Options* options, bool source_map_embed );
    alias da_sass_option_set_source_map_contents = void function( Sass_Options* options, bool source_map_contents );
    alias da_sass_option_set_omit_source_map_url = void function( Sass_Options* options, bool omit_source_map_url );
    alias da_sass_option_set_is_indented_syntax_src = void function( Sass_Options* options, bool is_indented_syntax_src );
    alias da_sass_option_set_indent = void function( Sass_Options* options, const(char)* indent );
    alias da_sass_option_set_linefeed = void function( Sass_Options* options, const(char)* linefeed );
    alias da_sass_option_set_input_path = void function( Sass_Options* options, const(char)* input_path );
    alias da_sass_option_set_output_path = void function( Sass_Options* options, const(char)* output_path );
    alias da_sass_option_set_image_path = void function( Sass_Options* options, const(char)* image_path );
    alias da_sass_option_set_include_path = void function( Sass_Options* options, const(char)* include_path );
    alias da_sass_option_set_source_map_file = void function( Sass_Options* options, const(char)* source_map_file );
    alias da_sass_option_set_c_functions = void function( Sass_Options* options, Sass_C_Function_List c_functions );
    alias da_sass_option_set_importer = void function( Sass_Options* options, Sass_C_Import_Callback importer );

    alias da_sass_context_get_output_string = const(char)* function( Sass_Context* ctx );
    alias da_sass_context_get_error_status = int function( Sass_Context* ctx );
    alias da_sass_context_get_error_json = const(char)* function( Sass_Context* ctx );
    alias da_sass_context_get_error_message = const(char)* function( Sass_Context* ctx );
    alias da_sass_context_get_error_file = const(char)* function( Sass_Context* ctx );
    alias da_sass_context_get_error_line = size_t function( Sass_Context* ctx );
    alias da_sass_context_get_error_column = size_t function( Sass_Context* ctx );
    alias da_sass_context_get_source_map_string = const(char)* function( Sass_Context* ctx );
    alias da_sass_context_get_included_files = char** function( Sass_Context* ctx );

    alias da_sass_context_take_error_json = char* function( Sass_Context* ctx );
    alias da_sass_context_take_error_message = char* function( Sass_Context* ctx );
    alias da_sass_context_take_error_file = char* function( Sass_Context* ctx );
    alias da_sass_context_take_output_string = char* function( Sass_Context* ctx );
    alias da_sass_context_take_source_map_string = char* function( Sass_Context* ctx );

    alias da_sass_option_push_include_path = void function( Sass_Options* options, const(char)* path );

    alias da_sass_string_quote =  char* function( const(char)* str, const(char) quotemark );
    alias da_sass_string_unquote = char* function( const(char)* str );

    alias da_libsass_version = const(char)* function();

    alias da_sass2scss = char* function( const(char)* sass, const(int) options );
    alias da_sass2scss_version = const(char)* function();
}

__gshared {
    da_sass_make_options sass_make_options;
    da_sass_make_file_context sass_make_file_context;
    da_sass_make_data_context sass_make_data_context;
    
    da_sass_compile_file_context sass_compile_file_context;
    da_sass_compile_data_context sass_compile_data_context;
    
    da_sass_make_file_compiler sass_make_file_compiler;
    da_sass_make_data_compiler sass_make_data_compiler;
    
    da_sass_compiler_parse sass_compiler_parse;
    da_sass_compiler_execute sass_compiler_execute;
    
    da_sass_delete_compiler sass_delete_compiler;
    
    da_sass_delete_file_context sass_delete_file_context;
    da_sass_delete_data_context sass_delete_data_context;
    
    da_sass_file_context_get_context sass_file_context_get_context;
    da_sass_data_context_get_context sass_data_context_get_context;
    
    da_sass_context_get_options sass_context_get_options;
    da_sass_file_context_get_options sass_file_context_get_options;
    da_sass_data_context_get_options sass_data_context_get_options;
    da_sass_file_context_set_options sass_file_context_set_options;
    da_sass_data_context_set_options sass_data_context_set_options;
    
    da_sass_option_get_precision sass_option_get_precision;
    da_sass_option_get_output_style sass_option_get_output_style;
    da_sass_option_get_source_comments sass_option_get_source_comments;
    da_sass_option_get_source_map_embed sass_option_get_source_map_embed;
    da_sass_option_get_source_map_contents sass_option_get_source_map_contents;
    da_sass_option_get_omit_source_map_url sass_option_get_omit_source_map_url;
    da_sass_option_get_is_indented_syntax_src sass_option_get_is_indented_syntax_src;
    da_sass_option_get_indent sass_option_get_indent;
    da_sass_option_get_linefeed sass_option_get_linefeed;
    da_sass_option_get_input_path sass_option_get_input_path;
    da_sass_option_get_output_path sass_option_get_output_path;
    da_sass_option_get_image_path sass_option_get_image_path;
    da_sass_option_get_include_path sass_option_get_include_path;
    da_sass_option_get_source_map_file sass_option_get_source_map_file;
    da_sass_option_get_c_functions sass_option_get_c_functions;
    da_sass_option_get_importer sass_option_get_importer;
    
    da_sass_option_set_precision sass_option_set_precision;
    da_sass_option_set_output_style sass_option_set_output_style;
    da_sass_option_set_source_comments sass_option_set_source_comments;
    da_sass_option_set_source_map_embed sass_option_set_source_map_embed;
    da_sass_option_set_source_map_contents sass_option_set_source_map_contents;
    da_sass_option_set_omit_source_map_url sass_option_set_omit_source_map_url;
    da_sass_option_set_is_indented_syntax_src sass_option_set_is_indented_syntax_src;
    da_sass_option_set_indent sass_option_set_indent;
    da_sass_option_set_linefeed sass_option_set_linefeed;
    da_sass_option_set_input_path sass_option_set_input_path;
    da_sass_option_set_output_path sass_option_set_output_path;
    da_sass_option_set_image_path sass_option_set_image_path;
    da_sass_option_set_include_path sass_option_set_include_path;
    da_sass_option_set_source_map_file sass_option_set_source_map_file;
    da_sass_option_set_c_functions sass_option_set_c_functions;
    da_sass_option_set_importer sass_option_set_importer;
    
    da_sass_context_get_output_string sass_context_get_output_string;
    da_sass_context_get_error_status sass_context_get_error_status;
    da_sass_context_get_error_json sass_context_get_error_json;
    da_sass_context_get_error_message sass_context_get_error_message;
    da_sass_context_get_error_file sass_context_get_error_file;
    da_sass_context_get_error_line sass_context_get_error_line;
    da_sass_context_get_error_column sass_context_get_error_column;
    da_sass_context_get_source_map_string sass_context_get_source_map_string;
    da_sass_context_get_included_files sass_context_get_included_files;
    
    da_sass_context_take_error_json sass_context_take_error_json;
    da_sass_context_take_error_message sass_context_take_error_message;
    da_sass_context_take_error_file sass_context_take_error_file;
    da_sass_context_take_output_string sass_context_take_output_string;
    da_sass_context_take_source_map_string sass_context_take_source_map_string;
    
    da_sass_option_push_include_path sass_option_push_include_path;
    
    da_sass_string_quote sass_string_quote;
    da_sass_string_unquote sass_string_unquote;
    
    da_libsass_version libsass_version;
    
    da_sass2scss sass2scss;
    da_sass2scss_version sass2scss_version;
}

class DerelictSassLoader : SharedLibLoader {
    public this() {
        super( libNames );
    }
    
    protected override void loadSymbols() {
        bindFunc( cast( void** )&sass_make_options, "sass_make_options" );
        bindFunc( cast( void** )&sass_make_file_context, "sass_make_file_context" );
        bindFunc( cast( void** )&sass_make_data_context, "sass_make_data_context" );
        
        bindFunc( cast( void** )&sass_compile_file_context, "sass_compile_file_context" );
        bindFunc( cast( void** )&sass_compile_data_context, "sass_compile_data_context" );
        
        bindFunc( cast( void** )&sass_make_file_compiler, "sass_make_file_compiler" );
        bindFunc( cast( void** )&sass_make_data_compiler, "sass_make_data_compiler" );
        
        bindFunc( cast( void** )&sass_compiler_parse, "sass_compiler_parse" );
        bindFunc( cast( void** )&sass_compiler_execute, "sass_compiler_execute" );
        
        bindFunc( cast( void** )&sass_delete_compiler, "sass_delete_compiler" );
        
        bindFunc( cast( void** )&sass_delete_file_context, "sass_delete_file_context" );
        bindFunc( cast( void** )&sass_delete_data_context, "sass_delete_data_context" );
        
        bindFunc( cast( void** )&sass_file_context_get_context, "sass_file_context_get_context" );
        bindFunc( cast( void** )&sass_data_context_get_context, "sass_data_context_get_context" );
        

        bindFunc( cast( void** )&sass_context_get_options, "sass_context_get_options" );
        bindFunc( cast( void** )&sass_file_context_get_options, "sass_file_context_get_options" );
        bindFunc( cast( void** )&sass_data_context_get_options, "sass_data_context_get_options" );
        bindFunc( cast( void** )&sass_file_context_set_options, "sass_file_context_set_options" );
        bindFunc( cast( void** )&sass_data_context_set_options, "sass_data_context_set_options" );
        
        bindFunc( cast( void** )&sass_option_get_precision, "sass_option_get_precision" );
        bindFunc( cast( void** )&sass_option_get_output_style, "sass_option_get_output_style" );
        bindFunc( cast( void** )&sass_option_get_source_comments, "sass_option_get_source_comments" );
        bindFunc( cast( void** )&sass_option_get_source_map_embed, "sass_option_get_source_map_embed" );
        bindFunc( cast( void** )&sass_option_get_source_map_contents, "sass_option_get_source_map_contents" );
        bindFunc( cast( void** )&sass_option_get_omit_source_map_url, "sass_option_get_omit_source_map_url" );
        bindFunc( cast( void** )&sass_option_get_is_indented_syntax_src, "sass_option_get_is_indented_syntax_src" );
        bindFunc( cast( void** )&sass_option_get_indent, "sass_option_get_indent" );
        bindFunc( cast( void** )&sass_option_get_linefeed, "sass_option_get_linefeed" );
        bindFunc( cast( void** )&sass_option_get_input_path, "sass_option_get_input_path" );
        bindFunc( cast( void** )&sass_option_get_output_path, "sass_option_get_output_path" );
        bindFunc( cast( void** )&sass_option_get_image_path, "sass_option_get_image_path" );
        bindFunc( cast( void** )&sass_option_get_include_path, "sass_option_get_include_path" );
        bindFunc( cast( void** )&sass_option_get_source_map_file, "sass_option_get_source_map_file" );
        bindFunc( cast( void** )&sass_option_get_c_functions, "sass_option_get_c_functions" );
        bindFunc( cast( void** )&sass_option_get_importer, "sass_option_get_importer" );

        bindFunc( cast( void** )&sass_option_set_precision, "sass_option_set_precision" );
        bindFunc( cast( void** )&sass_option_set_output_style, "sass_option_set_output_style" );
        bindFunc( cast( void** )&sass_option_set_source_comments, "sass_option_set_source_comments" );
        bindFunc( cast( void** )&sass_option_set_source_map_embed, "sass_option_set_source_map_embed" );
        bindFunc( cast( void** )&sass_option_set_source_map_contents, "sass_option_set_source_map_contents" );
        bindFunc( cast( void** )&sass_option_set_omit_source_map_url, "sass_option_set_omit_source_map_url" );
        bindFunc( cast( void** )&sass_option_set_is_indented_syntax_src, "sass_option_set_is_indented_syntax_src" );
        bindFunc( cast( void** )&sass_option_set_indent, "sass_option_set_indent" );
        bindFunc( cast( void** )&sass_option_set_linefeed, "sass_option_set_linefeed" );
        bindFunc( cast( void** )&sass_option_set_input_path, "sass_option_set_input_path" );
        bindFunc( cast( void** )&sass_option_set_output_path, "sass_option_set_output_path" );
        bindFunc( cast( void** )&sass_option_set_image_path, "sass_option_set_image_path" );
        bindFunc( cast( void** )&sass_option_set_include_path, "sass_option_set_include_path" );
        bindFunc( cast( void** )&sass_option_set_source_map_file, "sass_option_set_source_map_file" );
        bindFunc( cast( void** )&sass_option_set_c_functions, "sass_option_set_c_functions" );
        bindFunc( cast( void** )&sass_option_set_importer, "sass_option_set_importer" );

        bindFunc( cast( void** )&sass_context_get_output_string, "sass_context_get_output_string" );
        bindFunc( cast( void** )&sass_context_get_error_status, "sass_context_get_error_status" );
        bindFunc( cast( void** )&sass_context_get_error_json, "sass_context_get_error_json" );
        bindFunc( cast( void** )&sass_context_get_error_message, "sass_context_get_error_message" );
        bindFunc( cast( void** )&sass_context_get_error_file, "sass_context_get_error_file" );
        bindFunc( cast( void** )&sass_context_get_error_line, "sass_context_get_error_line" );
        bindFunc( cast( void** )&sass_context_get_error_column, "sass_context_get_error_column" );
        bindFunc( cast( void** )&sass_context_get_source_map_string, "sass_context_get_source_map_string" );
        bindFunc( cast( void** )&sass_context_get_included_files, "sass_context_get_included_files" );

        bindFunc( cast( void** )&sass_context_take_error_json, "sass_context_take_error_json" );
        bindFunc( cast( void** )&sass_context_take_error_message, "sass_context_take_error_message" );
        bindFunc( cast( void** )&sass_context_take_error_file, "sass_context_take_error_file" );
        bindFunc( cast( void** )&sass_context_take_output_string, "sass_context_take_output_string" );
        bindFunc( cast( void** )&sass_context_take_source_map_string, "sass_context_take_source_map_string" );
        
        bindFunc( cast( void** )&sass_option_push_include_path, "sass_option_push_include_path" );
        
        bindFunc( cast( void** )&sass_string_quote, "sass_string_quote" );
        bindFunc( cast( void** )&sass_string_unquote, "sass_string_unquote" );
        
        bindFunc( cast( void** )&libsass_version, "libsass_version" );
        
        bindFunc( cast( void** )&sass2scss, "sass2scss" );
        bindFunc( cast( void** )&sass2scss_version, "sass2scss_version" );
    }
}

__gshared DerelictSassLoader DerelictSass;

shared static this() {
    DerelictSass = new DerelictSassLoader;
}