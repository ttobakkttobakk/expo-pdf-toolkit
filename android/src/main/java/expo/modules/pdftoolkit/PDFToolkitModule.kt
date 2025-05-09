package expo.modules.pdftoolkit

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.graphics.pdf.PdfRenderer
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.io.File
import java.io.FileOutputStream
import java.lang.Exception

/**
 * PDFToolkit 네이티브 모듈 클래스
 * PDF 파일을 이미지로 변환하고 관리하기 위한 기능을 제공합니다.
 */
class PDFToolkitModule : Module() {
  companion object {
    private const val TAG = "PDFToolkit"
  }

  /**
   * Promise를 메인 UI 쓰레드에서 안전하게 resolve하기 위한 유틸리티 함수
   */
  private fun safeResolve(promise: Promise, result: Any?) {
    try {
      appContext.reactContext?.let { reactContext ->
        Handler(reactContext.mainLooper).post {
          try {
            Log.d(TAG, "UI 쓰레드에서 Promise resolve 실행")
            promise.resolve(result)
            Log.d(TAG, "Promise resolve 완료")
          } catch (e: Exception) {
            Log.e(TAG, "UI 쓰레드에서 Promise resolve 실패: ${e.message}", e)
            safeReject(promise, "PROMISE_ERROR", "UI 쓰레드에서 Promise resolve 실패: ${e.message}", e)
          }
        }
      } ?: run {
        // reactContext가 null인 경우에 대한 처리
        Log.d(TAG, "ReactContext가 null임, 직접 resolve 실행")
        promise.resolve(result)
        Log.d(TAG, "Promise resolve 완료")
      }
    } catch (e: Exception) {
      Log.e(TAG, "safeResolve 실패: ${e.message}", e)
      safeReject(promise, "PROMISE_ERROR", "Promise resolve 오류: ${e.message}", e)
    }
  }
  
  /**
   * Promise를 메인 UI 쓰레드에서 안전하게 reject하기 위한 유틸리티 함수
   */
  private fun safeReject(promise: Promise, code: String, message: String, exception: Throwable?) {
    try {
      appContext.reactContext?.let { reactContext ->
        Handler(reactContext.mainLooper).post {
          try {
            Log.d(TAG, "UI 쓰레드에서 Promise reject 실행: $code - $message")
            promise.reject(code, message, exception)
            Log.d(TAG, "Promise reject 완료")
          } catch (e: Exception) {
            Log.e(TAG, "UI 쓰레드에서 Promise reject 실패: ${e.message}", e)
            // 여기서 재귀 호출은 피해야 함
            promise.reject(code, message, exception)
          }
        }
      } ?: run {
        // reactContext가 null인 경우에 대한 처리
        Log.d(TAG, "ReactContext가 null임, 직접 reject 실행")
        promise.reject(code, message, exception)
        Log.d(TAG, "Promise reject 완료")
      }
    } catch (e: Exception) {
      Log.e(TAG, "safeReject 실패: ${e.message}", e)
      // 최후의 수단으로 직접 reject
      promise.reject(code, message, exception)
    }
  }

  // PDF 리소스를 안전하게 닫기 위한 함수
  private fun safeClosePdfResources(renderer: PdfRenderer?, descriptor: ParcelFileDescriptor?) {
    try {
      renderer?.close()
      descriptor?.close()
      Log.d(TAG, "PDF 리소스 안전하게 닫힘")
    } catch (e: Exception) {
      Log.e(TAG, "PDF 리소스 닫기 실패: ${e.message}", e)
    }
  }

  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  override fun definition() = ModuleDefinition {
    // 모듈 이름 설정 (JS에서 접근할 이름)
    Name("PDFToolkit")

    // 이벤트 정의 (JS에서 구독 가능한 이벤트)
    Events("onProgress")

    // 비동기 함수 정의 (JS에서 호출 가능한 Promise 반환 함수)
    AsyncFunction("convertToImages") { pdfPath: String, options: HashMap<String, Any>, promise: Promise ->
      try {
        Log.d(TAG, "PDF 변환 시작: $pdfPath")
        val realPath = pdfPath.removePrefix("file://")
        val file = File(realPath)
        
        if (!file.exists() || !file.canRead()) {
          Log.e(TAG, "파일이 존재하지 않거나 읽을 수 없음: $realPath")
          safeReject(promise, "FILE_ERROR", "파일이 존재하지 않거나 읽을 수 없음: $realPath", null)
          return@AsyncFunction
        }
        
        // 옵션 파싱
        val scale = options["scale"] as? Double ?: 1.0
        val compressionQuality = options["compressionQuality"] as? Double ?: 0.7
        
        try {
          // PDF 파일 열기
          val fileDescriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
          val pdfRenderer = PdfRenderer(fileDescriptor)
          
          try {
            val total = pdfRenderer.pageCount
            if (total <= 0) {
              safeClosePdfResources(pdfRenderer, fileDescriptor)
              Log.e(TAG, "PDF에 페이지가 없음")
              safeReject(promise, "PDF_ERROR", "PDF에 페이지가 없음", null)
              return@AsyncFunction
            }
            
            Log.d(TAG, "PDF 페이지 수: $total")
            
            // 이미지 저장 경로 설정 (캐시 디렉토리)
            val cacheDir = appContext.cacheDirectory
            val imageDir = File(cacheDir, "pdf_images").apply { 
              if (!exists()) mkdirs()
            }
            
            val imagePaths = mutableListOf<String>()
            
            // PDF의 각 페이지를 이미지로 변환
            for (i in 0 until total) {
              // 현재 진행률 이벤트 발송
              sendEvent("onProgress", mapOf(
                "progress" to (i.toDouble() / total),
                "page" to (i + 1), // 1부터 시작하는 페이지 번호
                "total" to total
              ))
              
              try {
                // 페이지 열기
                val page = pdfRenderer.openPage(i)
                
                // 페이지 크기에 맞게 비트맵 생성
                val width = (page.width * scale).toInt()
                val height = (page.height * scale).toInt()
                
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                
                // 이미지 파일로 저장
                val imageFile = File(imageDir, "page_${i + 1}.jpg")
                val fos = FileOutputStream(imageFile)
                bitmap.compress(Bitmap.CompressFormat.JPEG, (compressionQuality * 100).toInt(), fos)
                fos.flush()
                fos.close()
                
                // 메모리 해제
                bitmap.recycle()
                
                // 페이지 닫기 (중요: 다음 페이지를 열기 전에 현재 페이지를 닫아야 함)
                page.close()
                
                // 이미지 경로 저장
                imagePaths.add("file://${imageFile.absolutePath}")
              } catch (e: Exception) {
                Log.e(TAG, "페이지 ${i + 1} 변환 실패: ${e.message}", e)
                // 개별 페이지 오류는 기록하지만 계속 진행
              }
            }
            
            // 완료 이벤트 전송 (100% 완료)
            sendEvent("onProgress", mapOf(
              "progress" to 1.0,
              "page" to total,
              "total" to total
            ))
            
            if (imagePaths.isEmpty()) {
              safeClosePdfResources(pdfRenderer, fileDescriptor)
              Log.e(TAG, "생성된 이미지 없음")
              safeReject(promise, "PDF_ERROR", "이미지를 하나도 생성하지 못했습니다", null)
              return@AsyncFunction
            }
            
            // 이미지 경로 리스트 반환
            Log.d(TAG, "변환 완료: ${imagePaths.size}개 이미지 생성. promise resolve 직전")
            
            // UI 쓰레드에서 Promise resolve 먼저 실행하고 나중에 리소스 정리
            safeResolve(promise, imagePaths)
            
            // Promise resolve 후 리소스 정리
            safeClosePdfResources(pdfRenderer, fileDescriptor)
            
          } catch (conversionError: Exception) {
            // 사용한 리소스 정리 시도
            safeClosePdfResources(pdfRenderer, fileDescriptor)
            
            Log.e(TAG, "PDF 변환 과정 오류: ${conversionError.message}", conversionError)
            safeReject(promise, "PDF_CONVERSION_ERROR", "PDF 변환 과정 오류: ${conversionError.message}", conversionError)
          }
        } catch (openError: Exception) {
          Log.e(TAG, "PDF 파일 열기 실패: ${openError.message}", openError)
          safeReject(promise, "PDF_OPEN_ERROR", "PDF 파일 열기 실패: ${openError.message}", openError)
        }
      } catch (e: Exception) {
        // 에러 발생 시 JS에 에러 전달
        Log.e(TAG, "PDF 변환 실패: ${e.message}", e)
        safeReject(promise, "PDF_ERROR", "PDF 변환 실패: ${e.message}", e)
      }
    }

    AsyncFunction("getFileName") { pdfPath: String, promise: Promise ->
      try {
        val realPath = pdfPath.removePrefix("file://")
        val file = File(realPath)
        Log.d(TAG, "파일 이름 추출: ${file.name}")
        
        safeResolve(promise, file.name)
      } catch (e: Exception) {
        Log.e(TAG, "파일 이름 가져오기 실패: ${e.message}", e)
        safeReject(promise, "FILE_NAME_ERROR", "파일 이름 가져오기 실패: ${e.message}", e)
      }
    }

    AsyncFunction("getPageThumbnail") { pdfPath: String, pageNumber: Int, options: HashMap<String, Any>, promise: Promise ->
      try {
        Log.d(TAG, "페이지 썸네일 변환 시작: $pdfPath, 페이지: $pageNumber")
        val realPath = pdfPath.removePrefix("file://")
        val file = File(realPath)
        
        if (!file.exists() || !file.canRead()) {
          Log.e(TAG, "파일이 존재하지 않거나 읽을 수 없음: $realPath")
          safeReject(promise, "FILE_ERROR", "파일이 존재하지 않거나 읽을 수 없음: $realPath", null)
          return@AsyncFunction
        }
        
        // 옵션 파싱
        val scale = options["scale"] as? Double ?: 1.0
        val compressionQuality = options["compressionQuality"] as? Double ?: 0.7
        
        Log.d(TAG, "옵션: scale=$scale, compressionQuality=$compressionQuality")
        
        var fileDescriptor: ParcelFileDescriptor? = null
        var pdfRenderer: PdfRenderer? = null
        
        try {
          // PDF 파일 열기
          fileDescriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
          pdfRenderer = PdfRenderer(fileDescriptor)
          
          // 페이지 번호 유효성 검사
          if (pageNumber < 0 || pageNumber >= pdfRenderer.pageCount) {
            safeClosePdfResources(pdfRenderer, fileDescriptor)
            Log.e(TAG, "해당 페이지 없음: $pageNumber")
            safeReject(promise, "PAGE_ERROR", "해당 페이지 없음", null) // 유효하지 않은 페이지 번호
            return@AsyncFunction
          }
          
          // 지정된 페이지 열기
          val page = pdfRenderer.openPage(pageNumber)
          
          try {
            // 페이지 크기에 맞게 비트맵 생성
            val width = (page.width * scale).toInt()
            val height = (page.height * scale).toInt()
            
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
            
            // 페이지는 사용 후 바로 닫기
            page.close()
            
            // 이미지 파일로 저장
            val cacheDir = appContext.cacheDirectory
            val imageDir = File(cacheDir, "pdf_thumbnails").apply { 
              if (!exists()) mkdirs() 
            }
            
            // 고유한 파일 이름 생성 (파일명+페이지+타임스탬프)
            val fileName = "${file.nameWithoutExtension}_p${pageNumber}_${System.currentTimeMillis()}.jpg"
            val imageFile = File(imageDir, fileName)
            
            val fos = FileOutputStream(imageFile)
            val success = bitmap.compress(Bitmap.CompressFormat.JPEG, (compressionQuality * 100).toInt(), fos)
            fos.flush()
            fos.close()
            
            // 메모리 해제
            bitmap.recycle()
            
            if (!success) {
              safeClosePdfResources(pdfRenderer, fileDescriptor)
              Log.e(TAG, "이미지 저장 실패")
              safeReject(promise, "PDF_ERROR", "이미지 저장 실패", null)
              return@AsyncFunction
            }
            
            // 변환된 이미지 경로 반환
            val imagePath = "file://${imageFile.absolutePath}"
            Log.d(TAG, "이미지 저장 성공. 프로미스 resolve 직전. 경로: $imagePath")
            
            try {
              // 단일 페이지 변환 완료 이벤트 전송 (100% 완료)
              sendEvent("onProgress", mapOf(
                "progress" to 1.0,
                "page" to (pageNumber + 1), // 1부터 시작하는 페이지 번호
                "total" to pdfRenderer.pageCount
              ))
              
              // UI 쓰레드에서 먼저 Promise resolve 실행 후 나중에 리소스 정리
              safeResolve(promise, imagePath)
              
              // Promise resolve 후 리소스 정리
              safeClosePdfResources(pdfRenderer, fileDescriptor)
              
            } catch (e: Exception) {
              Log.e(TAG, "Promise resolve 또는 이벤트 전송 오류: ${e.message}", e)
              safeClosePdfResources(pdfRenderer, fileDescriptor)
              safeReject(promise, "PROMISE_ERROR", "Promise resolve 또는 이벤트 전송 오류: ${e.message}", e)
            }
          } catch (e: Exception) {
            Log.e(TAG, "이미지 파일 저장 실패: ${e.message}", e)
            safeClosePdfResources(pdfRenderer, fileDescriptor)
            safeReject(promise, "FILE_SAVE_ERROR", "이미지 파일 저장 실패: ${e.message}", e)
          }
        } catch (e: Exception) {
          Log.e(TAG, "PDF 파일 열기 실패: ${e.message}", e)
          safeClosePdfResources(pdfRenderer, fileDescriptor)
          safeReject(promise, "PDF_OPEN_ERROR", "PDF 파일 열기 실패: ${e.message}", e)
        }
      } catch (e: Exception) {
        Log.e(TAG, "페이지 썸네일 변환 실패: ${e.message}", e)
        safeReject(promise, "PDF_ERROR", "페이지 썸네일 변환 실패: ${e.message}", e)
      }
    }
  }
}
