# DerelictSASS

A dynamic binding to [libsass](http://sass-lang.com) for the D Programming Language (*unofficial*). 

For information on how to build DerelictSASS and link it with your programs, please see the post [Using Derelict](http://dblog.aldacron.net/derelict-help/using-derelict/) at the The One With D.

### Building libsass
Clone libsass from it [repository](https://github.com/sass/libsass):
```bash
git clone git://github.com/sass/libsass.git
```
And then make it as shared library. Installation is optional.
```bash
make BUILD=shared
make install BUILD=shared
```

### Using DerelictSASS
For more information you can check [libsass](https://github.com/sass/libsass) and [sassc](https://github.com/sass/sassc) projects.
```d
import derelict.sass.sass;

void main ()
{
    // Load libsass library
    DerelictSass.load ();
    
    // Now libsass functions can be called
    ...
}
```
