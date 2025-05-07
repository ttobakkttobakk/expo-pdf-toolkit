package expo.modules.pdftoolkit

import android.content.Context
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.io.File
import java.io.FileOutputStream

class PDFToolkitModule : Module() {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  override fun definition() = ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('PDFToolkit')` in JavaScript.
    Name("PDFToolkit")

    // PDF를 이미지로 변환하는 메소드
    AsyncFunction("convertToImages") { pdfPath: String, promise: Promise ->
      try {
        // file:// prefix 제거
        val realPath = pdfPath.removePrefix("file://")
        val file = File(realPath)
        val fileDescriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
        val pdfRenderer = PdfRenderer(fileDescriptor)

        val imagePaths = mutableListOf<String>()
        val cacheDir = appContext.reactContext?.cacheDir ?: File("/tmp")

        // PDF 파일명 추출 (확장자 제외)
        val pdfNameWithoutExt = file.nameWithoutExtension

        for (pageIndex in 0 until pdfRenderer.pageCount) {
          val page = pdfRenderer.openPage(pageIndex)
          val width = page.width
          val height = page.height
          val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
          page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
          page.close()

          // 파일명 생성 및 저장
          val timestamp = System.currentTimeMillis()
          val fileName = "${pdfNameWithoutExt}_${timestamp}_page_$pageIndex.jpg"
          val imageFile = File(cacheDir, fileName)
          val fos = FileOutputStream(imageFile)
          bitmap.compress(Bitmap.CompressFormat.JPEG, 70, fos)
          fos.flush()
          fos.close()
          bitmap.recycle()  // 메모리 해제
          imagePaths.add("file://${imageFile.absolutePath}")
        }

        pdfRenderer.close()
        fileDescriptor.close()

        promise.resolve(imagePaths)
      } catch (e: Exception) {
        promise.reject("PDF_ERROR", "PDF 변환 실패: ${e.message}")
      }
    }

    // 파일 이름을 가져오는 메소드
    AsyncFunction("getFileName") { pdfPath: String, promise: Promise ->
      try {
        val realPath = pdfPath.removePrefix("file://")
        val file = File(realPath)
        promise.resolve(file.name)
      } catch (e: Exception) {
        promise.reject("FILE_NAME_ERROR", "파일 이름 가져오기 실패: ${e.message}")
      }
    }
  }
}
