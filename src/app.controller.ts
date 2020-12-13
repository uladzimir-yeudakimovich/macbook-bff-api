import { Controller, All, Req, HttpStatus, HttpService } from '@nestjs/common';
import { map } from 'rxjs/operators';
import { AppService } from './app.service';

@Controller()
export class AppController {
  private memoryCache = {};

  constructor(
    private readonly appService: AppService,
    private httpService: HttpService
  ) {}

  @All()
  bffService(@Req() req) { 
    console.log('originalUrl: ', req.originalUrl);
    console.log('method: ', req.method);
    console.log('body: ', req.body);

    const key = req.originalUrl;
    const recipient = req.originalUrl.split('/')[1];
    console.log('recipient: ', recipient);

    const recipientUrl = process.env[recipient];
    console.log('recipientUrl: ', recipientUrl);

    if (recipientUrl) {
      const axiosConfig = {
        method: req.method,
        url: `${recipientUrl}${req.originalUrl}`,
        ...(Object.keys(req.body || {}).length > 0 && {data: req.body})
      };
  
      console.log('axiosConfig: ', axiosConfig);

      if (this.memoryCache[key]) {
        console.log('Get data from cache');
        return this.memoryCache[key];
      } else {
        return this.httpService.request(axiosConfig).pipe(
          map(response => {
            console.log('response from recipient: ', response.data);
            if (key === '/products') {
              this.memoryCache[key] = response.data;
              console.log('Set data from cache');
              setTimeout(() => this.memoryCache[key] = null, 1000 * 60 * 2);
            }
            return response.data;
          })
        );
      }
    } else {
      return {
        statusCode: HttpStatus.BAD_GATEWAY,
        message: 'Cannot process request',
      };
    }
  }
}
