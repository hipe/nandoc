# NanDoc

## patches

The target audience of this document is developers of nanDoc, not users of nanDoc.

Each directory in the patches/ directory adjacent to this document is a 'patch' directory.  One level under that directory is a directory whose name corresponds to a certain gem.  All the files within that directory correspond to new versions of files that exist in that gem.

The idea is if we load each file in that directory we 'patch' the gem (dynamically, at runtime), but also we should be able to generate an actual contextual diff to actually patch the things.

end.