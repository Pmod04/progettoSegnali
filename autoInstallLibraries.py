import pip

def install(package):
    if hasattr(pip, 'main'):
        pip.main(['install', package])
    else:
        pip._internal.main(['install', package])

install('numpy')
install('pyadi-iio')
install('sounddevice')
install('scipy')
install('rich')