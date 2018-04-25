# Change Log

* **Next**
    * **Deprecation** `rangeEnabled` frame option. All frames have this option `true` on Pilosa 1.0.
    * **Deprecation** `inverseEnabled` frame option and `Frame:inverseBitmap`, `Frame:inverseTopn` and `Frame:inverseRange` functions. Inverse frames will be removed from Pilosa 1.0.
    * **Removal** Index options. Use Frame options for each frame in the index instead.
    
* **v0.1.0** (2017-11-09):
    * Initial version.
    * Supports Pilosa Server v0.7.1.
