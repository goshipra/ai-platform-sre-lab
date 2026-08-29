pipeline {
  agent any

  environment {
    APP_REPO = 'https://github.com/goshipra/rag-mlops-pipeline.git'
    GITOPS_REPO = 'https://github.com/goshipra/ai-platform-sre-lab.git'
    IMAGE_REPO = 'ghcr.io/goshipra/rag-mlops-pipeline'
    GITOPS_PATH = 'apps/rag/overlays/local/kustomization.yaml'
  }

  stages {
    stage('Checkout application') {
      steps {
        dir('app') {
          git branch: 'main', url: env.APP_REPO
        }
        script {
          env.IMAGE_TAG = sh(
            script: 'git -C app rev-parse --short=12 HEAD',
            returnStdout: true
          ).trim()
        }
      }
    }

    stage('Unit tests') {
      steps {
        dir('app') {
          sh '''
            python3 -m venv .venv
            .venv/bin/python -m pip install --no-cache-dir pytest
            .venv/bin/python -m pytest -q
          '''
        }
      }
    }

    stage('Build image') {
      steps {
        sh 'docker build --pull -t ${IMAGE_REPO}:${IMAGE_TAG} app'
      }
    }

    stage('Publish image') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'ghcr-credentials',
          usernameVariable: 'GHCR_USER',
          passwordVariable: 'GHCR_TOKEN'
        )]) {
          sh '''
            set +x
            printf '%s' "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
            docker push "${IMAGE_REPO}:${IMAGE_TAG}"
            docker logout ghcr.io
          '''
        }
      }
    }

    stage('Update desired state') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'github-credentials',
          usernameVariable: 'GITHUB_USER',
          passwordVariable: 'GITHUB_TOKEN'
        )]) {
          sh '''
            rm -rf gitops
            git clone "${GITOPS_REPO}" gitops
            sed -i "s/newTag: .*/newTag: ${IMAGE_TAG}/" "gitops/${GITOPS_PATH}"
            git -C gitops config user.name "Jenkins CI"
            git -C gitops config user.email "jenkins-ci@users.noreply.github.com"
            git -C gitops add "${GITOPS_PATH}"
            git -C gitops diff --cached --quiet || git -C gitops commit -m "deploy: rag ${IMAGE_TAG}"
            set +x
            git -C gitops \
              -c credential.helper='!f() { echo "username=$GITHUB_USER"; echo "password=$GITHUB_TOKEN"; }; f' \
              push origin main
          '''
        }
      }
    }
  }

  post {
    always {
      sh 'docker image rm ${IMAGE_REPO}:${IMAGE_TAG} 2>/dev/null || true'
      deleteDir()
    }
  }
}
