using PyCall

pygui_start(:qt5)

@pyimport sys
@pyimport PyQt5
@pyimport PyQt5.QtCore as Core
@pyimport PyQt5.QtGui as Gui
@pyimport PyQt5.QtWidgets as Qt
@pyimport PyQt5.uic as UiC

# function main()
app = Qt.QApplication(sys.argv)

main_window = UiC.loadUi("src/gui/ui/mainwindow.ui")
central = main_window[:findChild](Qt.QWidget, "centralwidget")
navigation = main_window[:findChild](Qt.QWidget, "navigation")
placeholder = main_window[:findChild](Qt.QWidget, "content")

preprocess = UiC.loadUi("src/gui/ui/file_preprocess.ui")

placeholder[:setVisible](false)
central[:layout]()[:replaceWidget](placeholder, preprocess)

main_window[:show]()
app[:exec_]()
# end

# main()
