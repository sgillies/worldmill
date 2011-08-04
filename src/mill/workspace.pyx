# Copyright (c) 2007, Sean C. Gillies
# All rights reserved.
# See ../LICENSE.txt

cimport ograpi

from mill import ogrinit
from mill.collection import Collection


cdef class Workspace:

    # Path to actual data storage
    cdef public path
    # Feature collections
    cdef _collections
    
    # Name of OGR driver used in workspace
    cdef _format
    
    def __init__(self, path):
        self.path = path
        self._collections = None
        self._format = None

    def _read_collections(self):
        cdef void * cogr_ds
        cdef void * cogr_layer
        cdef void * cogr_layerdefn
        collections = {}

        # start session
        cogr_ds = ograpi.OGROpen(self.path, 0, NULL)
        
        # Silence null pointer errors if there are no layers
        # At some point this should be changed to a custom handler
        ograpi.CPLSetErrorHandler(ograpi.CPLQuietErrorHandler)

        n = ograpi.OGR_DS_GetLayerCount(cogr_ds)        
        for i in range(n):
            cogr_layer = ograpi.OGR_DS_GetLayer(cogr_ds, i)
            cogr_layerdefn = ograpi.OGR_L_GetLayerDefn(cogr_layer)
            layer_name = ograpi.OGR_FD_GetName(cogr_layerdefn)
            collection = Collection(layer_name, self)
            collections[layer_name] = collection
        
        # Explicitly set format to None if workspace has no layers
        if n == 0:
            self._format = None
        else:
            driver = ograpi.OGR_DS_GetDriver(cogr_ds)
            self._format = ograpi.OGR_Dr_GetName(driver)
        
        # end session
        ograpi.OGR_DS_Destroy(cogr_ds)
        
        return collections

    property collections:
        # A lazy property
        def __get__(self):
            if not self._collections:
                self._collections = self._read_collections()
            return self._collections
            
    property format:
        def __get__(self):
            if not self._format:
                self._read_collections()
            return self._format

    def __getitem__(self, name):
        return self.collections.__getitem__(name)

    def keys(self):
        return self.collections.keys()
   
    def values(self):
        return self.collections.values()

    def items(self):
        return self.collections.items()


def workspace(path):
    return Workspace(path)

