package aws

import (
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"mime/multipart"
	"path"
)

const (
	AWS_S3_REGION = "us-east-2"
	AWS_S3_BUCKET = "windmill-warehouse"
)

var sess = connectAWS()

func connectAWS() *session.Session {
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

	fmt.Println("success")
	return "/users/" + userId + "/profile" + filename, nil
}

func UploadVideoToS3(file multipart.File, filename string, userId string) (string, error) {

	uploader := s3manager.NewUploader(sess)

	_, err := uploader.Upload(&s3manager.UploadInput{
		Bucket: aws.String(AWS_S3_BUCKET),
		Key:    aws.String(path.Join("/users/" + userId + "/videos", filename)),
		Body:   file,
	})

	if err != nil {
		return "", errors.New("error uploading to server")
	}

	fmt.Println("success")
	return "successful upload", nil
}

func listBuckets() {
	svc := s3.New(sess)
	input := &s3.ListObjectsInput{
		Bucket: aws.String(AWS_S3_BUCKET),
	}

	result, err := svc.ListObjects(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case s3.ErrCodeNoSuchBucket:
				fmt.Println(s3.ErrCodeNoSuchBucket, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			// Print the error, cast err to awserr.Error to get the Code and
			// Message from an error.
			fmt.Println(err.Error())
		}
		// Do your error handling here
		return
	}

	for _, item := range result.Contents {
		fmt.Println("<li>File %s</li>", *item.Key)
	}


}
