import ExpoModulesCore
import PDFKit
import UIKit

/**
 * PDFToolkit 네이티브 모듈 클래스
 * PDF 파일을 이미지로 변환하고 관리하기 위한 기능을 제공합니다.
 */
public class PDFToolkitModule: Module {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  public func definition() -> ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('PDFToolkit')` in JavaScript.
    Name("PDFToolkit")

    /**
     * PDF 파일의 모든 페이지를 개별 이미지로 변환하는 메소드
     * @param pdfPath PDF 파일 경로 (file:// 프리픽스 포함 가능)
     * @param options 옵션 (scale: 이미지 크기 비율, 1.0 = 원본 크기)
     * @return 변환된 이미지 파일 경로 리스트
     */
    AsyncFunction("convertToImages") { (pdfPath: String, options: [String: Any]?, promise: Promise) in
      print("convertToImages 호출됨: 경로=\(pdfPath), 옵션=\(String(describing: options))")
      
      // options 객체 안전하게 처리
      let safeOptions = options ?? [:]
      
      // file:// URI 프리픽스 제거 (iOS의 URL은 file:// 없이 사용)
      let path = pdfPath.replacingOccurrences(of: "file://", with: "")
      
      // 이미지 스케일 옵션 (기본값: 1.0 = 원본 크기)
      let scale = safeOptions["scale"] as? CGFloat ?? 1.0
      
      // 이미지 압축률 옵션 (기본값: 0.7 = 70%)
      let compressionQuality = safeOptions["compressionQuality"] as? CGFloat ?? 0.7
      
      // PDFDocument로 PDF 파일 로드 실패 시 에러 반환
      guard let doc = PDFDocument(url: URL(fileURLWithPath: path)) else {
        promise.reject(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "PDF 로드 실패"]))
        return
      }
      
      // PDF 파일 경로에서 파일명 추출 (확장자 제외)
      let pdfURL = URL(fileURLWithPath: path)
      let pdfNameWithoutExt = pdfURL.deletingPathExtension().lastPathComponent
      var imagePaths: [String] = []
      let total = doc.pageCount
      
      // 진행률 업데이트를 위한 스텝 수 설정 (한 페이지당 몇 번의 이벤트 전송할지)
      let stepsPerPage = 10
      
      // 모든 PDF 페이지를 순회하며 이미지로 변환
      for pageIndex in 0..<total {
        // 현재 페이지 가져오기
        guard let page = doc.page(at: pageIndex) else { continue }
        
        // 페이지 크기와 회전 각도 확인
        let pageRect = page.bounds(for: .mediaBox)
        let rotation = page.rotation
        print("페이지 \(pageIndex+1) 크기: \(pageRect.size.width) x \(pageRect.size.height), 회전=\(rotation)")
        
        // 페이지의 원본 크기 (회전 전)
        let originalWidth = pageRect.size.width
        let originalHeight = pageRect.size.height
        
        // 회전을 고려한 최종 크기 계산
        var finalWidth = originalWidth
        var finalHeight = originalHeight
        
        // 90도, 270도 회전인 경우 가로세로 전환
        if rotation == 90 || rotation == 270 {
          finalWidth = originalHeight
          finalHeight = originalWidth
        }
        
        // 스케일 적용
        let scaledWidth = finalWidth * scale
        let scaledHeight = finalHeight * scale
        
        // 이미지 렌더러 생성
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: scaledWidth, height: scaledHeight))
        
        // 페이지를 이미지로 렌더링
        let image = renderer.image { ctx in
          let context = ctx.cgContext
          
          // 배경을 흰색으로 채움
          UIColor.white.setFill()
          context.fill(CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
          
          // 좌표계 설정 (스케일 및 원점 이동)
          context.saveGState()
          
          // iOS의 좌표계는 상단 왼쪽이 원점(0,0)이고, PDF는 하단 왼쪽이 원점이므로
          // PDF 좌표계를 iOS 좌표계로 변환하기 위해 Y축을 뒤집고 변환
          context.translateBy(x: 0, y: scaledHeight)
          context.scaleBy(x: 1.0, y: -1.0)
          
          // 스케일 적용
          context.scaleBy(x: scale, y: scale)
          
          // 회전 처리
          switch rotation {
          case 0:
            // 기본 방향 (회전 없음)
            break
            
          case 90:
            // 시계 방향 90도 회전
            context.translateBy(x: originalHeight, y: 0)
            context.rotate(by: .pi / 2)
            break
            
          case 180:
            // 180도 회전
            context.translateBy(x: originalWidth, y: originalHeight)
            context.rotate(by: .pi)
            break
            
          case 270:
            // 시계 방향 270도 회전
            context.translateBy(x: 0, y: originalWidth)
            context.rotate(by: 3 * .pi / 2)
            break
            
          default:
            // 다른 각도의 회전은 PDFKit의 기본 메커니즘 사용
            let centerX = originalWidth / 2
            let centerY = originalHeight / 2
            context.translateBy(x: centerX, y: centerY)
            context.rotate(by: CGFloat(rotation) * .pi / 180)
            context.translateBy(x: -centerX, y: -centerY)
          }
          
          // PDF 페이지 그리기
          page.draw(with: .mediaBox, to: context)
          
          context.restoreGState()
        }
        
        // 이미지를 JPEG로 변환하고 임시 디렉토리에 저장
        if let data = image.jpegData(compressionQuality: compressionQuality) {
          // 파일명에 타임스탬프 추가하여 중복 방지
          let timestamp = Int(Date().timeIntervalSince1970 * 1000)
          let fileName = "\(timestamp)_page_\(pageIndex).jpg"
          
          // 임시 디렉토리 경로에 파일 저장
          let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
          try? data.write(to: URL(fileURLWithPath: filePath))
          
          // 저장된 이미지 경로를 리스트에 추가 (JS에서 접근 가능하도록 file:// 프리픽스 추가)
          imagePaths.append("file://" + filePath)
        }
        
        // 페이지별로 stepsPerPage만큼 쪼개서 진행률 이벤트 전송 (더 부드러운 진행률 업데이트)
        for step in 1...stepsPerPage {
          // 진행률 계산: 현재 페이지와 스텝을 기반으로 0~1 사이 값 계산
          // (pageIndex + step/stepsPerPage) / total
          // 예: 5페이지 중 2페이지 3스텝/10스텝 = (2.3/5) = 0.46 = 46%
          let progress = (Double(pageIndex) + Double(step) / Double(stepsPerPage)) / Double(total)
          
          // JS로 진행률 이벤트 전송
          self.sendEvent("onProgress", [
            "progress": progress, // 0~1 사이의 진행률
            "page": pageIndex + 1, // 1부터 시작하는 현재 페이지 번호
            "total": total // 전체 페이지 수
          ])
        }
      }
      
      // 변환된 이미지 경로 리스트 반환
      promise.resolve(imagePaths)
    }

    /**
     * PDF 파일의 이름만 추출하는 메소드
     * @param pdfPath PDF 파일 경로
     * @return 파일명 (경로 제외, 확장자 포함)
     */
    AsyncFunction("getFileName") { (pdfPath: String, promise: Promise) in
      let url = URL(fileURLWithPath: pdfPath)
      let fileName = url.lastPathComponent // 파일 경로에서 파일명만 추출
      promise.resolve(fileName)
    }

    /**
     * PDF 파일의 특정 페이지만 이미지로 변환하는 메소드
     * @param pdfPath PDF 파일 경로
     * @param pageNumber 추출할 페이지 번호 (0부터 시작)
     * @param options 옵션 (scale: 이미지 크기 비율, 1.0 = 원본 크기)
     * @return 변환된 이미지 파일 경로
     */
    AsyncFunction("getPageThumbnail") { (pdfPath: String, pageNumber: Int, options: [String: Any]?, promise: Promise) in
      print("getPageThumbnail 호출됨: 경로=\(pdfPath), 페이지=\(pageNumber), 옵션=\(String(describing: options))")
      
      // options 객체 안전하게 처리
      let safeOptions = options ?? [:]
      
      // file:// URI 프리픽스 제거
      let path = pdfPath.replacingOccurrences(of: "file://", with: "")
      
      // 이미지 스케일 옵션 (기본값: 1.0 = 원본 크기)
      let scale = safeOptions["scale"] as? CGFloat ?? 1.0
      
      // 이미지 압축률 옵션 (기본값: 0.7 = 70%)
      let compressionQuality = safeOptions["compressionQuality"] as? CGFloat ?? 0.7
      
      // PDF 문서 로드 확인
      guard let doc = PDFDocument(url: URL(fileURLWithPath: path)) else {
        print("PDF 로드 실패: \(path)")
        promise.reject(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "PDF 로드 실패"]))
        return
      }
      
      print("PDF 로드 성공: 페이지 수=\(doc.pageCount)")
      
      // 페이지 번호 유효성 검사
      guard let page = doc.page(at: pageNumber) else {
        print("해당 페이지 없음: \(pageNumber)")
        promise.reject(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "해당 페이지 없음"]))
        return
      }
      
      // 페이지 크기와 회전 각도 확인
      let pageRect = page.bounds(for: .mediaBox)
      let rotation = page.rotation
      print("페이지 크기: \(pageRect.size.width) x \(pageRect.size.height), 회전=\(rotation)")
      
      // 페이지의 원본 크기 (회전 전)
      let originalWidth = pageRect.size.width
      let originalHeight = pageRect.size.height
      
      // 회전을 고려한 최종 크기 계산
      var finalWidth = originalWidth
      var finalHeight = originalHeight
      
      // 90도, 270도 회전인 경우 가로세로 전환
      if rotation == 90 || rotation == 270 {
        finalWidth = originalHeight
        finalHeight = originalWidth
      }
      
      // 스케일 적용
      let scaledWidth = finalWidth * scale
      let scaledHeight = finalHeight * scale
      
      // 이미지 렌더러 생성
      let renderer = UIGraphicsImageRenderer(size: CGSize(width: scaledWidth, height: scaledHeight))
      
      // 이미지 렌더링
      let image = renderer.image { ctx in
        let context = ctx.cgContext
        
        // 배경을 흰색으로 채움
        UIColor.white.setFill()
        context.fill(CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
        
        // 좌표계 설정 (스케일 및 원점 이동)
        context.saveGState()
        
        // iOS의 좌표계는 상단 왼쪽이 원점(0,0)이고, PDF는 하단 왼쪽이 원점이므로
        // PDF 좌표계를 iOS 좌표계로 변환하기 위해 Y축을 뒤집고 변환
        context.translateBy(x: 0, y: scaledHeight)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // 스케일 적용
        context.scaleBy(x: scale, y: scale)
        
        // 회전 처리
        switch rotation {
        case 0:
          // 기본 방향 (회전 없음)
          break
          
        case 90:
          // 시계 방향 90도 회전
          context.translateBy(x: originalHeight, y: 0)
          context.rotate(by: .pi / 2)
          break
          
        case 180:
          // 180도 회전
          context.translateBy(x: originalWidth, y: originalHeight)
          context.rotate(by: .pi)
          break
          
        case 270:
          // 시계 방향 270도 회전
          context.translateBy(x: 0, y: originalWidth)
          context.rotate(by: 3 * .pi / 2)
          break
          
        default:
          // 다른 각도의 회전은 PDFKit의 기본 메커니즘 사용
          let centerX = originalWidth / 2
          let centerY = originalHeight / 2
          context.translateBy(x: centerX, y: centerY)
          context.rotate(by: CGFloat(rotation) * .pi / 180)
          context.translateBy(x: -centerX, y: -centerY)
        }
        
        // PDF 페이지 그리기
        page.draw(with: .mediaBox, to: context)
        
        context.restoreGState()
      }
      
      // 이미지를 JPEG로 저장
      if let data = image.jpegData(compressionQuality: compressionQuality) {
        // 파일명 생성 및 임시 경로에 저장
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let pdfURL = URL(fileURLWithPath: path)
        let pdfNameWithoutExt = pdfURL.deletingPathExtension().lastPathComponent
        let fileName = "\(timestamp)_page_\(pageNumber).jpg"
        let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
        
        do {
          try data.write(to: URL(fileURLWithPath: filePath))
          print("이미지 저장 성공: \(filePath)")
          
          // 단일 페이지 변환 완료 이벤트 전송 (100% 완료)
          self.sendEvent("onProgress", [
            "progress": 1.0, // 100% 완료
            "page": pageNumber + 1, // 1부터 시작하는 페이지 번호
            "total": doc.pageCount // 전체 페이지 수
          ])
          
          // 변환된 이미지 경로 반환
          let resultPath = "file://" + filePath
          print("반환할 경로: \(resultPath)")
          promise.resolve(resultPath)
          return
        } catch {
          print("이미지 저장 실패: \(error.localizedDescription)")
          promise.reject(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "이미지 저장 실패: \(error.localizedDescription)"]))
          return
        }
      }
      
      // 이미지 변환 실패 시 에러 반환
      print("이미지 변환 실패")
      promise.reject(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "이미지 변환 실패"]))
    }
  }
}
