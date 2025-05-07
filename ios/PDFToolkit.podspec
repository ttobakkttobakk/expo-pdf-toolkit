# package.json 파일을 읽기 위한 json 라이브러리 불러오기
require 'json'

# 상위 디렉토리의 package.json 파일 읽어서 파싱
package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

# Pod 스펙 정의 시작
Pod::Spec.new do |s|
  # 모듈의 기본 정보 설정
  s.name           = 'PDFToolkit'                    # 모듈 이름
  s.version        = package['version']              # package.json의 버전
  s.summary        = package['description']          # 모듈 요약 설명
  s.description    = package['description']          # 모듈 상세 설명
  s.license        = package['license']              # 라이선스 정보
  s.author         = package['author']               # 작성자 정보
  s.homepage       = package['homepage']             # 홈페이지 URL

  # 지원하는 플랫폼 버전 설정
  s.platforms      = {
    :ios => '15.1',                                 # iOS 최소 지원 버전
    :tvos => '15.1'                                 # tvOS 최소 지원 버전
  }

  # Swift 버전 설정
  s.swift_version  = '5.4'

  # 소스 코드 위치 설정
  s.source         = { git: 'https://github.com/ttobakkttobakk/react-native-pdf-toolkit' }

  # 정적 프레임워크 사용 설정
  s.static_framework = true

  # Expo 모듈 코어 의존성 추가
  s.dependency 'ExpoModulesCore'

  # Swift와 Objective-C 호환성 설정
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  # 포함할 소스 파일 패턴 설정
  # h: 헤더 파일
  # m, mm: Objective-C 소스 파일
  # swift: Swift 소스 파일
  # hpp, cpp: C++ 소스 파일
  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp}"
end