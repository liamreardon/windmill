package aws

import (
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/joho/godotenv"
	"log"
	"mime/multipart"
	"os"
	"path"
)

var AWS_S3_BASE string
var AWS_S3_REGION string
var AWS_S3_BUCKET string

func initEnv() {
	if err := godotenv.Load(); err != nil {
		log.Print("No .env file found")
	}

	AWS_S3_BASE = os.Getenv("AWS_S3_BASE")
	AWS_S3_REGION = os.Getenv("AWS_S3_REGION")
	AWS_S3_BUCKET = os.Getenv("AWS_S3_BUCKET")
}

var sess = connectAWS()

func connectAWS() *session.Session {
	initEnv()
	sess, err := session.NewSession(
		&aws.Config{
			Region: aws.String(AWS_S3_REGION),
		})

	if err != nil {
		panic(err)
	}
	return sess
}

func UpdateDisplayPicture(file multipart.File, filename string, userId string) (string, error) {
	uploader := s3manager.NewUploader(sess)

	_, err := uploader.Upload(&s3manager.UploadInput{
		Bucket: aws.String(AWS_S3_BUCKET),
		Key:    aws.String(path.Join("/users/" + userId + "/profile", filename)),
		Body:   file,
	})

	if err != nil {
		// Do your error handling here
		return "", errors.New("error uploading to server")
	}

	return AWS_S3_BASE + userId + "/profile/" + filename, nil
}

func UploadVideoToS3(file multipart.File, videoId string, userId string) (string, error) {
	uploader := s3manager.NewUploader(sess)

	_, err := uploader.Upload(&s3manager.UploadInput{
		Bucket: aws.String(AWS_S3_BUCKET),
		Key:    aws.String(path.Join("/users/" + userId + "/videos", videoId + ".mp4")),
		Body:   file,
	})

	if err != nil {
		return "", errors.New("error uploading to server")
	}

	fmt.Println("success")
	return AWS_S3_BASE + userId + "/videos/" + videoId + ".mp4", nil
}

func GetUserDisplayPicture(dpPath string) (*os.File, error){
	item := "displaypic.jpg"

	file, err := os.Create(item)
	if err != nil {
		fmt.Println(err)
	}

	downloader := s3manager.NewDownloader(sess)

	numBytes, err := downloader.Download(file,
		&s3.GetObjectInput{
			Bucket: aws.String(AWS_S3_BUCKET),
			Key: aws.String(dpPath),
		})
	if err != nil {
		return nil, errors.New("couldn't download profile picture")
	}
	fmt.Println("Downloaded", file.Name(), numBytes, "bytes")
	return file, nil
}

func UploadVideoThumbnail(file multipart.File, userId string, videoId string) (string, error) {
	uploader := s3manager.NewUploader(sess)

	_, err := uploader.Upload(&s3manager.UploadInput{
		Bucket: aws.String(AWS_S3_BUCKET),
		ContentType: aws.String("image/jpeg"),
		Key:    aws.String(path.Join("/users/" + userId + "/videoThumbnails", videoId + ".jpg")),
		Body:   file,
	})

	if err != nil {
		return "", errors.New("error uploading to server")
	}

	fmt.Println("success")

	return AWS_S3_BASE + userId + "/videoThumbnails/" + videoId+ ".jpg", nil
}
