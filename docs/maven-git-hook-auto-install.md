# Maven + Git Hook 자동 설치 가이드

## 개요

Maven 프로젝트에서 native git hook을 자동으로 설치하는 방법을 정리한 참고 문서.
`./mvnw compile` 또는 `./mvnw initialize` 실행 시 `.git/hooks/pre-commit`이 자동 설치된다.

## 현재 프로젝트 구조와의 관계

이 프로젝트는 **Claude Code 전용 hook**만 사용 중이다:

```
.claude/hooks/
├── pre-commit-harness.sh   # 7가지 검증 (BUILD-01~03, QUAL-01~02, CONV-01~02)
├── protect-files.sh         # 보호 파일 수정 차단
└── post-edit-verify.sh     # 편집 후 컴파일 확인

.git/hooks/
└── *.sample                 # native hook 없음 (sample 파일만 존재)
```

Claude Code 바깥에서 직접 `git commit`하면 모든 검증이 우회된다.
Native git hook을 추가하면 이 gap을 보완할 수 있다.

## 방법: maven-antrun-plugin 사용

### 1. Hook 스크립트 준비

프로젝트 루트에 `hooks/` 디렉토리를 만들고 hook 스크립트를 작성한다:

```
project-root/
├── hooks/
│   └── pre-commit          # git으로 추적되는 hook 스크립트
├── .claude/hooks/           # Claude Code 전용 hook (기존)
└── pom.xml
```

`hooks/pre-commit` 예시:

```sh
#!/bin/sh
# Native git pre-commit hook
# Claude Code hook(.claude/hooks/pre-commit-harness.sh)과 동일한 검증 수행

echo "=== Pre-commit Hook ==="

# BUILD-01: 컴파일 확인
echo "[BUILD-01] Checking compilation..."
./mvnw compile -q 2>/dev/null
if [ $? -ne 0 ]; then
  echo "FAIL [BUILD-01] Compilation failed."
  exit 1
fi

# BUILD-02: 테스트 실행
echo "[BUILD-02] Running tests..."
./mvnw test -q 2>/dev/null
if [ $? -ne 0 ]; then
  echo "FAIL [BUILD-02] Tests failed."
  exit 1
fi

# BUILD-03: 코드 포맷 확인
echo "[BUILD-03] Checking code format..."
./mvnw spotless:check -q 2>/dev/null
if [ $? -ne 0 ]; then
  echo "FAIL [BUILD-03] Code formatting issues found. Run: ./mvnw spotless:apply"
  exit 1
fi

# QUAL-01: System.out.println 금지
if grep -rn "System\.out\.print" src/main/java/ 2>/dev/null | grep -v "//.*System\.out" > /dev/null; then
  echo "FAIL [QUAL-01] System.out.println found. Use org.jboss.logging.Logger instead."
  exit 1
fi

echo "=== All checks passed ==="
```

### 2. pom.xml에 자동 설치 플러그인 추가

```xml
<plugin>
  <artifactId>maven-antrun-plugin</artifactId>
  <executions>
    <execution>
      <id>install-git-hooks</id>
      <phase>initialize</phase>
      <goals><goal>run</goal></goals>
      <configuration>
        <target>
          <copy file="${project.basedir}/hooks/pre-commit"
                tofile="${project.basedir}/.git/hooks/pre-commit"
                overwrite="true"/>
          <chmod file="${project.basedir}/.git/hooks/pre-commit" perm="755"/>
        </target>
      </configuration>
    </execution>
  </executions>
</plugin>
```

### 3. 동작 흐름

```
팀원이 프로젝트 clone
       ↓
./mvnw compile (또는 ./mvnw initialize)
       ↓
maven-antrun-plugin이 hooks/pre-commit → .git/hooks/pre-commit 복사
       ↓
이후 git commit 시 native hook 자동 실행
```

## 대안: git core.hooksPath 사용

Maven 플러그인 없이 git 설정만으로도 가능하다:

```bash
git config core.hooksPath hooks/
```

이 방법은 `.git/hooks/`에 복사하지 않고 `hooks/` 디렉토리를 직접 참조한다.
`.gitconfig`나 프로젝트 README에 이 설정을 안내하면 된다.

단, 팀원이 수동으로 설정해야 하므로 자동화 수준은 Maven 방식보다 낮다.

## 적용 시 고려사항

| 항목 | 설명 |
|------|------|
| **중복 방지** | Claude Code hook과 native hook의 검증 로직이 중복될 수 있음. native hook이 `.claude/hooks/pre-commit-harness.sh`를 호출하는 래퍼 방식을 권장 |
| **우회 가능성** | `git commit --no-verify`로 native hook도 우회 가능. 완전한 차단이 필요하면 서버 사이드 hook(CI/CD)을 추가해야 함 |
| **프로젝트 목적** | 데모/교육용이면 Claude Code hook만으로 충분. 실무 팀 프로젝트면 native hook 추가 권장 |
| **CI/CD 연계** | native hook + CI pipeline 검증을 조합하면 가장 견고한 구조 |

## 참고 자료

- [Git Hooks 공식 문서](https://git-scm.com/docs/githooks)
- [maven-antrun-plugin 문서](https://maven.apache.org/plugins/maven-antrun-plugin/)
- [Git core.hooksPath 설정](https://git-scm.com/docs/git-config#Documentation/git-config.txt-corehooksPath)
