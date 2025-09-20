[serial vs pyserial](https://stackoverflow.com/questions/60034429/importerror-cannot-import-name-serial-from-serial-unknown-location)


RuntimeError:  [RxPacketError] Input voltage error!
I found this out that one of the servos was the wrong kind. So the serial loading process doesn't work. 

### Servos:
| Left port | Right port |
|------------|-----------|
| `data out` | `data in` |

* connect to calibration via the `data in`